# Autocompletion using Trie data structure

This is an implementation of autocompletion using Trie data structure. The Trie is built using a dictionary of words and the user can enter a prefix to get all the words that start with that prefix.

The implementation can be found in the file [trie.ex](https://github.com/rwillians/trie-autocomplete/blob/main/lib/trie.ex). Although it's a 300+ lines file, most of it is documentation and tests. The actual implementation is quite small and simple.

## Do you want to take it for a spin?

### TL;DR: Run on Docker

> **Note**
> At the moment the image only supports arm64 architecture.

I've built and published a docker image with 25k+ English words (from [@dolph/dictionary](https://github.com/dolph/dictionary/tree/master)).

Completions:

    ```bash
    docker run ghcr.io/rwillians/trie-autocomplete:latest trie.completions "ba"
    ```

Search:

    ```bash
    docker run ghcr.io/rwillians/trie-autocomplete:latest trie.search "ba"
    ```

Benchmark:

    ```bash
    docker run ghcr.io/rwillians/trie-autocomplete:latest trie.search --benchmark "ba"
    ```

    ```bash
    docker run ghcr.io/rwillians/trie-autocomplete:latest trie.completions --benchmark "ba"
    ```

Those commands will run a benchmarked of `completions` and `search` functions for the given prefix. They run for about 35 seconds.

### Running Local

This project uses [asdf](https://asdf-vm.com/#/core-manage-asdf-vm) to manage Elixir's and Erlang's versions. If you have `asdf` installed, you can run `asdf install` to install the correct version of Elixir and Erlang.

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

Completions:

```elixir
Trie.Bench.get_dictionary()
|> Trie.completions("appl")
```

Search :

```elixir
Trie.Bench.get_dictionary()
|> Trie.search("appl")
```

Benchmark:

```elixir
Trie.Bench.completions("appl")
```

```elixir
Trie.Bench.search("appl")
```

#### Mix commands

Completions:

```bash
mix trie.completions "ag"
```

Search:

```bash
mix trie.search "ag"
```

Benchmark:

```bash
mix trie.completions --benchmark "ag"
```

```bash
mix trie.search --benchmark "ag"
```

## Benchmark

Benchmark is done using [Benchee](https://github.com/bencheeorg/benchee).

```text
$> docker run ghcr.io/rwillians/trie-autocomplete:latest trie.completions --benchmark "ba"

Operating System: Linux
CPU Information: Unrecognized processor
Number of Available Cores: 4
Available memory: 9.72 GB
Elixir 1.15.1
Erlang 25.3.2.3

Benchmark suite executing with the following configuration:
warmup: 5 s
time: 20 s
memory time: 10 s
reduction time: 0 ns
parallel: 1
inputs: completions
Estimated total run time: 35 s

Measured function call overhead as: 0 ns
Benchmarking completions with input completions ...

##### With input completions #####
Name                  ips        average  deviation         median         99th %
completions       12.56 K       79.62 μs    ±23.67%       69.71 μs      144.33 μs

Memory usage statistics:

Name           Memory usage
completions       106.78 KB

**All measurements for memory usage were the same**

Profiling completions with eprof...

Profile results of #PID<0.30447.2>
#                                                          CALLS     % TIME µS/CALL
Total                                                       7718 100.0  886    0.11
Trie.to_key/1                                                  1  0.00    0    0.00
Trie.get_completions/1                                         1  0.00    0    0.00
Trie.completions/2                                             1  0.00    0    0.00
Trie.calculate_words/1                                         1  0.00    0    0.00
Map.get/2                                                      2  0.00    0    0.00
anonymous fn/2 in Trie.Bench.completions/2                     1  0.00    0    0.00
anonymous fn/2 in Benchee.Benchmark.Runner.main_function/2     1  0.00    0    0.00
:unicode.characters_to_binary/1                                1  0.00    0    0.00
Trie.get_node/2                                                3  0.11    1    0.33
Map.get/3                                                      2  0.11    1    0.50
:erlang.apply/2                                                1  0.23    2    2.00
:unicode.characters_to_binary/2                                1  0.23    2    2.00
:lists.reverse/2                                              45  1.35   12    0.27
Trie.with_prefix/2                                           766  5.08   45    0.06
:lists.reverse/1                                             767  5.64   50    0.07
Trie.append/2                                                765  6.32   56    0.07
:erlang.++/2                                                 765  6.66   59    0.08
:maps.values/1                                               766  8.69   77    0.10
Enum.concat/2                                                765 10.95   97    0.13
Trie.get_children/1                                          766 12.30  109    0.14
Trie.with_prefix/3                                          1531 12.75  113    0.07
Trie.calculate_words/2                                       766 29.57  262    0.34

Profile done over 22 matching functions

Found 329 completions
```
