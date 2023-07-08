defmodule Trie.Bench do
  @moduledoc """
  This module is compiled with all the words and is meant to be used with the
  prebuilt docker image published in this repository's packages.

  Compiling the dictionary with all 25k+ English words might take a couple of
  minutes.
  """

  start = DateTime.utc_now()

  require Trie

  @external_resource "priv/assets/popular.txt"

  # The amount of memory used for compiling this is rediculous!
  # At runtime it's consuming a fair amount of RAM, about ~48MB -- most of
  # which is the taken by the beam vm --, but at compile
  # time it's using about 2GB. At the moment, I assume that's the cost for
  # the compiler to transpile all structs' ast into erlang's tuples and
  # lists.
  @dictionary File.stream!(@external_resource)
              |> Enum.into(Trie.new_root())

  @doc """
  Returns the compiled dictionary of words.
  """
  def get_dictionary, do: @dictionary

  @doc """
  Loads all the words from a text file (one word per line) into a dictionary
  (using the Trie data structure).

  The operation is profiled and its stats are printed to the console.
  """
  @spec load!(file :: String.t()) :: Trie.t()
  def load!(file \\ @external_resource) do
    start = DateTime.utc_now()

    dictionary =
      File.stream!(file)
      |> Enum.into(Trie.new_root())

    stop = DateTime.utc_now()
    time = DateTime.diff(stop, start, :millisecond)

    IO.puts("Compiled dictionary in #{time} ms")

    dictionary
  end

  @benchee_opts time: 20,
                warmup: 5,
                memory_time: 10,
                profile_after: true,
                measure_function_call_overhead: true,
                formatters: [Benchee.Formatters.Console],
                print: %{
                  benchmarking: true,
                  fast_warning: true,
                  configuration: true
                }

  @doc """
  Runs a benchmark for {Trie.completions/2} for the given prefix.
  """
  @spec completions(dictionary :: Trie.t(), prefix :: String.t()) :: :ok
  def completions(dictionary \\ @dictionary, prefix) do
    spec = %{
      "completions" => &Trie.completions(dictionary, &1)
    }

    Benchee.run(spec, @benchee_opts ++ [inputs: %{"completions" => prefix}])

    completions = Trie.completions(dictionary, prefix)

    IO.puts("Found #{length(completions)} completions")
    IO.puts("")

    :ok
  end

  @doc """
  Runs a benchmark for {Trie.search/2} for the given prefix.
  """
  @spec search(dictionary :: Trie.t(), prefix :: String.t()) :: :ok
  def search(dictionary \\ @dictionary, prefix) do
    spec = %{
      "search" => &Trie.search(dictionary, &1)
    }

    Benchee.run(spec, @benchee_opts ++ [inputs: %{"search" => prefix}])

    results = Trie.search(dictionary, prefix)

    IO.puts("Found #{length(results)} words")
    IO.puts("")

    :ok
  end

  stop = DateTime.utc_now()
  time = DateTime.diff(stop, start, :millisecond)

  IO.puts("Compiled dictionary in #{time} ms")
end
