#!/usr/bin/env bash

set -evx

openmm_version="8.4"
benchmark_options="--platform CUDA"

platform="$(uname)"
architecture="$(uname -m)"
miniforge="Miniforge3-${platform}-${architecture}.sh"
working_path="$(pwd -P)"
prefix="${working_path}/miniforge3"
environment="openmm_benchmark"
output_file="benchmark.json"

curl -LOfv "https://github.com/conda-forge/miniforge/releases/latest/download/${miniforge}"
chmod +x "${miniforge}"
"./${miniforge}" -b -p "${prefix}"
eval "$("${prefix}/bin/conda" shell.bash hook)"
conda create -y -n "${environment}" "openmm=${openmm_version}"
conda activate "${environment}"
python -m openmm.testInstallation
cd "${prefix}/envs/${environment}/share/openmm/examples/benchmarks"
python benchmark.py ${benchmark_options} --style table --outfile "${working_path}/${output_file}" --verbose
