#!/usr/bin/env bash

set -evx

# Git tag of OpenMM version to benchmark:
openmm_tag="8.4.0"

# Number of replicates to run:
replicates="3"

# Default arguments:
default_arguments="--platform CUDA --style table --verbose"

# Get environment information.
current_directory="$(pwd -P)"
platform="$(uname)"
architecture="$(uname -m)"
cuda_version="$(nvidia-smi | grep "CUDA Version" | cut -d : -f 3 | cut -d "|" -f 1 | xargs)"
processors="$(nproc)"

# Set script variables.
working_directory="${current_directory}/benchmark"
miniforge="Miniforge3-${platform}-${architecture}.sh"
miniforge_prefix="${working_directory}/miniforge3"
miniforge_environment="openmm_benchmark"
openmm_prefix="${miniforge_prefix}/envs/${miniforge_environment}"
miniforge_packages="cmake make cython swig doxygen numpy setuptools scipy cuda-toolkit=${cuda_version}"

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

# Patch benchmark script to add deterministic force option.
git apply - <<EOF
diff --git a/examples/benchmarks/benchmark.py b/examples/benchmarks/benchmark.py
index e1a50f161..49071d996 100644
--- a/examples/benchmarks/benchmark.py
+++ b/examples/benchmarks/benchmark.py
@@ -356,2 +356,4 @@ def runOneTest(testName, options):
         properties['DisablePmeStream'] = 'true'
+    if options.deterministic_forces:
+        properties['DeterministicForces'] = 'true'
     if options.opencl_platform is not None and 'OpenCLPlatformIndex' in platform.getPropertyNames():
@@ -483,2 +485,3 @@ parser.add_argument('--bond-constraints', default='hbonds', dest='bond_constrain
 parser.add_argument('--disable-pme-stream', default=False, action='store_true', dest='disable_pme_stream', help='disable use of a separate GPU stream for PME')
+parser.add_argument('--deterministic-forces', default=False, action='store_true', dest='deterministic_forces', help='enable deterministic forces')
 parser.add_argument('--device', default=None, dest='device', help='device index for CUDA, HIP, or OpenCL')
EOF

# Run CMake.
mkdir build
cd build
cmake -DBUILD_TESTING=OFF "-DCMAKE_INSTALL_PREFIX=${openmm_prefix}" -DOPENMM_BUILD_CPU_LIB=OFF -DOPENMM_BUILD_HIP_LIB=OFF -DOPENMM_BUILD_OPENCL_LIB=OFF ..
make "-j${processors}" install
make PythonInstall

# Test OpenMM.
cd ../..
python -m openmm.testInstallation

# Run benchmarks.
cd "${openmm_prefix}/examples/benchmarks"
for replicate in $(seq 1 "${replicates}"); do
    echo "Running replicate ${replicate} of ${replicates}..."
    batch=1
    for arguments in "$@"; do
        echo "Running batch ${batch} of arguments: ${arguments}"
        xargs python benchmark.py ${default_arguments} --outfile "${current_directory}/benchmark_r${replicate}_b${batch}.json" <<< "${arguments}"
        batch="$((${batch} + 1))"
    done
    if [ "${batch}" -eq 1 ]; then
        echo "Running with default arguments"
        python benchmark.py ${default_arguments} --outfile "${current_directory}/benchmark_r${replicate}_b${batch}.json"
    fi
done
