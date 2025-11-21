#!/usr/bin/env python

import json
import statistics
import sys

def main():
    json_paths = sys.argv[1:]
    if not json_paths:
        sys.exit("provide paths to JSON files containing benchmark results as arguments")

    replicates = []
    for json_path in json_paths:
        with open(json_path) as json_file:
            replicates.append(json.load(json_file))

    if len(set(map(get_replicate_info, replicates))) != 1:
        sys.exit("ERROR: information differs between replicates; results not comparable!")

    for key, value in replicates[0]["system"].items():
        print(f"{key}: {value}")
        if key == "timestamp":
            for replicate in replicates[1:]:
                timestamp = replicate["system"]["timestamp"]
                print(f"           {timestamp}")

    print()
    print("Test              Precision   Constraints   H mass (amu)   dt (fs)   Ensemble   Platform   ns/day (median)")

    benchmark_names = [benchmark["test"] for benchmark in replicates[0]["benchmarks"]]
    for benchmark_name in benchmark_names:
        benchmarks = [get_benchmark(replicate, benchmark_name) for replicate in replicates]
        if len(set(map(get_benchmark_info, benchmarks))) != 1:
            sys.exit("ERROR: information differs between benchmarks; results not comparable!")
        ns_per_day = [benchmark["ns_per_day"] for benchmark in benchmarks]
        benchmark = benchmarks[0]
        print("{:<18}{:<12}{:<14}{:<15}{:<10g}{:<11}{:<11}{:g}".format(
            benchmark_name,
            benchmark["precision"],
            benchmark["constraints"],
            benchmark["hydrogen_mass"],
            benchmark["timestep_in_fs"],
            benchmark["ensemble"],
            benchmark["platform"],
            statistics.median(ns_per_day)
        ))

# Retrieves all of the information for a replicate that should be the same between replicates.
def get_replicate_info(replicate):
    system_info = replicate["system"].copy()
    del system_info["timestamp"]
    return tuple(sorted(system_info.items()))

# Looks up a benchmark by name.
def get_benchmark(replicate, benchmark_name):
    benchmarks = [benchmark for benchmark in replicate["benchmarks"] if benchmark["test"] == benchmark_name]
    if len(benchmarks) != 1:
        sys.exit("ERROR: missing or duplicate benchmarks; results not comparable!")
    return benchmarks[0]

# Retrieves all of the information for a benchmark that should be the same between replicates.
def get_benchmark_info(benchmark):
    benchmark = benchmark.copy()
    benchmark["platform_properties"] = tuple(sorted(benchmark["platform_properties"].items()))
    del benchmark["steps"]
    del benchmark["elapsed_time"]
    del benchmark["ns_per_day"]
    return tuple(sorted(benchmark.items()))

if __name__ == "__main__":
    main()
