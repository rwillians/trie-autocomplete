# Autocompletion using Trie data structure

This project uses Trie data structure as a dictionary against which a prefix can be queried to get completions for matching words.

There are 3 implementation, [Trie.A](https://github.com/rwillians/trie-autocomplete/blob/main/lib/trie_a.ex), [Trie.B](https://github.com/rwillians/trie-autocomplete/blob/main/lib/trie_b.ex) and [Trie.C](https://github.com/rwillians/trie-autocomplete/blob/main/lib/trie_c.ex), each one with variations on how to represent the
data structure.

Code examples in their functions' documentation are actually tests, using ExUnit's doctest.

## Do you want to take it for a spin?

### TL;DR: Run on Docker

> **Note**
> I have only tested the docker image against arm64, not sure if it's working for amd64 yet.

The image is preloaded with a set of words from [@dolph/dictionary](https://github.com/dolph/dictionary/tree/master) containing 170k+ words.

Get completions:

    ```bash
    docker run ghcr.io/rwillians/trie-autocomplete:latest trie.completions "ba"
    ```

Run benchmark:

    ```bash
    docker run ghcr.io/rwillians/trie-autocomplete:latest trie.completions --benchmark "ba"
    ```

### Running Local

This project uses [asdf](https://asdf-vm.com/#/core-manage-asdf-vm) to manage Elixir's and Erlang's version. If you have `asdf` installed, you can run `asdf install` to install the correct version of Elixir and Erlang.

Install dependencies:

```bash
mix deps.get
```

Compile:

```bash
mix compile
```

#### Interactive shell

```bash
iex -S mix
```

Load a set of words (text files with one word per line):

```elixir
dict = File.stream!("priv/assets/popular.txt") |> Enum.into(%Trie.A{})
```

Get completions:

```elixir
Trie.completions(dict, "appl")
```

#### Mix commands

Completions:

```bash
mix trie.completions "ag"
```

Benchmark:

```bash
mix trie.completions --benchmark "ag"
```

## Benchmark

Benchmark is done using [Benchee](https://github.com/bencheeorg/benchee).

> **Note** the dataset of 25k words contain only 329 words that start with "ba" while the dataset of 170k words contains 1800.

```
$> mix trie.completions --benchmark "ba"

Loading dictionaries...
Operating System: macOS
CPU Information: Apple M1 Pro
Number of Available Cores: 10
Available memory: 16 GB
Elixir 1.15.2
Erlang 26.0.2

Benchmark suite executing with the following configuration:
warmup: 5 s
time: 20 s
memory time: 10 s
reduction time: 0 ns
parallel: 1
inputs: none specified
Estimated total run time: 3.50 min

Measured function call overhead as: 0 ns
Benchmarking Trie.A 170k ...
Benchmarking Trie.A 25k ...
Benchmarking Trie.B 170k ...
Benchmarking Trie.B 25k ...
Benchmarking Trie.C 170k ...
Benchmarking Trie.C 25k ...

Name                  ips        average  deviation         median         99th %
Trie.A 25k        15.47 K       64.64 μs    ±56.92%       51.71 μs      228.50 μs
Trie.C 25k         6.75 K      148.14 μs    ±69.04%       96.96 μs      456.75 μs
Trie.B 25k         6.49 K      154.15 μs    ±66.55%      102.88 μs      459.71 μs
Trie.A 170k        3.45 K      290.24 μs    ±74.26%      244.38 μs     1196.96 μs
Trie.C 170k        1.66 K      602.67 μs    ±68.16%      416.05 μs     1771.33 μs
Trie.B 170k        1.60 K      623.29 μs    ±67.56%      434.46 μs     1827.27 μs

Comparison: 
Trie.A 25k        15.47 K
Trie.C 25k         6.75 K - 2.29x slower +83.50 μs
Trie.B 25k         6.49 K - 2.38x slower +89.51 μs
Trie.A 170k        3.45 K - 4.49x slower +225.60 μs
Trie.C 170k        1.66 K - 9.32x slower +538.04 μs
Trie.B 170k        1.60 K - 9.64x slower +558.65 μs

Memory usage statistics:

Name           Memory usage
Trie.A 25k        110.77 KB
Trie.C 25k        176.36 KB - 1.59x memory usage +65.59 KB
Trie.B 25k        176.40 KB - 1.59x memory usage +65.63 KB
Trie.A 170k       531.53 KB - 4.80x memory usage +420.77 KB
Trie.C 170k       843.94 KB - 7.62x memory usage +733.17 KB
Trie.B 170k       843.98 KB - 7.62x memory usage +733.21 KB
```

## Observations

* Using structs to represent nodes has consistently shown to be must effective
  for both performance and memory usage -- `Trie.A`.

* To my surprise, representing a char by it's unicode integer code severely
  hurt performance and memory consumption -- {Trie.B} -- in comparison to 
  storing them as erlangs binary string -- `Trie.A`.

* Using tuples (triples, actually) to represent a node wasn't benefitial in any
  way -- `Trie.C`. It hurt performance, memory consumption and decreased
  redability of the code.

* The memory consumed to get completions seems ok-ish for now, but I wonder if
  I can decrese the amount of memory consumed by the dictionary. Needs further
  profiling.
