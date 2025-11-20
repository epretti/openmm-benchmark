#!/usr/bin/env bash

set -evx

# Git tag of OpenMM version to benchmark:
openmm_tag="8.4.0"

# Get environment information.
current_directory="$(pwd -P)"
platform="$(uname)"
architecture="$(uname -m)"
cuda_version="$(nvidia-smi --version | grep CUDA | cut -d : -f 2 | xargs)"
processors="$(nproc)"

# Set script variables.
working_directory="${current_directory}/benchmark"
miniforge="Miniforge3-${platform}-${architecture}.sh"
miniforge_prefix="${working_directory}/miniforge3"
miniforge_environment="openmm_benchmark"
openmm_prefix="${miniforge_prefix}/envs/${miniforge_environment}"
miniforge_packages="cmake make cython swig doxygen numpy setuptools cuda-toolkit=${cuda_version}"

# Create a directory to work in.
mkdir -p "${working_directory}"
cd "${working_directory}"

# Set up Conda.
curl -LOfv "https://github.com/conda-forge/miniforge/releases/latest/download/${miniforge}"
chmod +x "${miniforge}"
"./${miniforge}" -b -p "${miniforge_prefix}"
eval "$("${miniforge_prefix}/bin/conda" shell.bash hook)"

# Set up build environment.
conda create -y -n "${miniforge_environment}" ${miniforge_packages}
conda activate "${miniforge_environment}"

# Fetch OpenMM.
git clone https://github.com/openmm/openmm.git
cd openmm
git checkout "${openmm_tag}"
mkdir build
cd build

# Run CMake.
cmake -DBUILD_TESTING=OFF "-DCMAKE_INSTALL_PREFIX=${openmm_prefix}" -DOPENMM_BUILD_CPU_LIB=OFF -DOPENMM_BUILD_HIP_LIB=OFF -DOPENMM_BUILD_OPENCL_LIB=OFF ..
make "-j${processors}" install
make PythonInstall

# Test OpenMM.
cd ../..
python -m openmm.testInstallation

# Run benchmarks.
cd "${openmm_prefix}/examples/benchmarks"
python benchmark.py --platform CUDA --style table --outfile "${current_directory}/benchmark.json" --verbose
