# `openmm-benchmark`

A script to automatically download and install OpenMM build dependencies, build
OpenMM from source, then run the OpenMM benchmark suite and save the results.

Can run with:

```
curl -LOf https://raw.githubusercontent.com/epretti/openmm-benchmark/refs/heads/master/openmm-benchmark.sh && chmod +x openmm-benchmark.sh && ./openmm-benchmark.sh
```

Arguments are passed on from `openmm-benchmark.sh` to OpenMM's `benchmark.py`,
so, *e.g.*, you can run a multi-GPU benchmark by replacing
`./openmm-benchmark.sh` with

```
./openmm-benchmark.sh "--test=amber20-cellulose,amber20-stmv --device=0,1,..."
```

(Use the actual device indices for the GPUs you want to benchmark.)

Arguments to pass should be quoted into a single argument; if multiple arguments
are given to the script, `benchmark.py` will be run multiple times.  This can be
useful to perform multiple sets of benchmarks at once with different sets of
settings.  If no arguments are given at all, benchmarks will be run once with
default options.

The script patches `benchmark.py` after cloning the OpenMM repository to add a
`--deterministic-forces` flag that enables the `DeterministicForces` platform
option.

Run `analyze.py` with JSON files output by the benchmark script as arguments to
summarize benchmark results.
