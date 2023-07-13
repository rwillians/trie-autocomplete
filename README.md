# Autocompletion using Trie data structure

This project uses Trie data structure as a dictionary against which a prefix can be queried to get completions for matching words.

There are 3 implementation, [Trie.A](https://github.com/rwillians/trie-autocomplete/blob/main/lib/trie_a.ex) (most performant), [Trie.B](https://github.com/rwillians/trie-autocomplete/blob/main/lib/trie_b.ex) and [Trie.C](https://github.com/rwillians/trie-autocomplete/blob/main/lib/trie_c.ex), each one with variations on how to represent the
data structure.

Code examples in their functions' documentation are actually tests, using ExUnit's doctest.


## TL;DR:

[Run on Docker](#run-on-docker).


## How does it word?

The idea for using Trie for autocompletion is to divide the problem in 2 major steps:

1. follow the prefix typed as deep as we can in our Trie dictionary;
2. compute the possible (if any) completions we can provide.

The first step assumes we already have our dictionary of words as a Trie, so I'll skip the explanition for how to compute it.

Given we have a dictionary with the words "bird", "bite", "bites", "cat" and dog, our Trie dictionary would look like:

```
===========================================
L0   L1   L2   L3   L4   L5    end of word?
---- ---- ---- ---- ---- ---- -------------
root                                  false
     b                                false
          i                           false
               r                      false
                    d                  true
               t                      false
                    e                  true
                         s             true
     c                                false
          a                           false
               t                       true
     d                                false
          o                           false
               g                       true
===========================================
```

Let's imagine the user typed only the letter "d" so far. Just like in a real dictionary, ours is sorted alphabetically meaning that we don't need to go through all the nodes to find node `d`, we can got straight to it and retrieve it -- `O(1)`. That's possible by having a hash table mapping all child nodes that `root` node has -- and the same is true for any node in our Trie.

The `d` node we retrieved looks like this:

```
=============================
L0   L1   L2     end of word?
---- ---- ---- --------------
d                       false
     o                  false
          g              true
=============================
```

Now it's time to move to the second and final step towards the solution: calculating the possible completions.
For this example, it's as simple as concatenating the value of each children node from `d` up untill the last nodes:

```
=============================
L0   L1   L2     end of word?
---- ---- ---- --------------
d   ┌─┐                 false
    │o│  ┌─┐            false
    └─┘  │g│             true
         └─┘
=============================
```

`"o" + "g" = "og"`

Our only possible completion is "og".

But what if the user had typed "bi" instead?

In that case we'd retrieve the node `root.b`, which looks like:

```
======================================
L0   L1   L2   L3   L4    end of word?
---- ---- ---- ---- ---- -------------
b                                false
     i                           false
          r                      false
               d                  true
          t                      false
               e                  true
                    s             true
======================================
```

We sill have one more letter typed by the user, letter "i", so we repeat the process.
We retrieve the node `i` from node `b`. It looks like this:

```
=================================
L0   L1   L2   L3    end of word?
---- ---- ---- ---- -------------
i                           false
     r                      false
          d                  true
     t                      false
          e                  true
               s             true
=================================
```

Now we're as deeps as the letters typed by the user can get us, so it's time to calculate the possible completions.

It's a bit trickier this time becase there are 3 known words we can complete: "ird" (for "bird"), "ite" (for "bite") and "ites" (for "bites"). So it's not as simple as just concatenating the child nodes -- but it's still somewhat simple -- and we'll make use of that flag "end of word?". The trickest thing about this is that we'll use recursion.

For each child of `i` (nodes `r` and `t`), we'll assign to it an empty accumulator `acc1 = ""` (empty string), forming a Tuple containing the node itself and the accumulator. There's also gonna be a second accumulator containing the completions we come up with: `acc2 = []`. 

Then, we'll iterate over the tuples:
* we'll concatenate the value of the node with the first accumulator: `acc1 += "r"` (e.g: `acc1 = "" + "r"`);
* if the node is flaged as `end of word?`, then we add its concatenated value (e.g: `"r"`) to the completions accumulator (not the case for `"r"` but will be the case for `"rd"`, `"ite"` and `"ites"`);
* for each child node that the current node has (e.g: `r` has nodes `[d]`, `e` has nodes `[s]` and `s` has `[]`) we assign an accumulator containing the concatenation so far (`acc1` -- e.g `"r"`) and append it to the list of remaining nodes we need to iterate over;
* repeate untill there's no more nodes we need to iterate over -- `O(n)` where `n` is the number of child nodes used to calculate completions.

Recursion is one of those things that's harder to explain than to do it. Here's one way the code can look like:

```elixir
def calculate_words([{node, wip_completion} = _head | rest_of_nodes], completions) do
  #                         ^ acc1                                    ^ acc2
  wip_completion = wip_completion <> node.value

  children_to_be_calculated =
    for child <- node.children,
        do: {child, wip_completion}

  maybe_updated_completions =
    if node.end_of_word?,
       do: completions ++ [wip_completion],
       else: completions

  calculate_words(children_to_be_calculated ++ rest_of_nodes, maybe_updated_completions)
end

def calculate_words([], completions), do: completions
#                   ^ no more nodes to iterate over

completions = calculate_words([{node_b_i_r, ""}, {node_b_i_t, ""}], [])
# ^ completions = ["ird", "ite", "ites"]
```

You can see the actual implementation for that on file [trie_a.ex:207](https://github.com/rwillians/trie-autocomplete/blob/main/lib/trie_a.ex#L207).


## Do you want to take it for a spin?

### Run on Docker

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

Benchmark done using [Benchee](https://github.com/bencheeorg/benchee).

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

### Observations

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
