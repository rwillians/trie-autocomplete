defmodule Mix.Tasks.Trie.Completions do
  @moduledoc """
  Get completions for a given prefix (case insensitve) using a dictionary of
  170k+ English words:

      ```sh
      mix trie.completions "ag"
      ```

  Benchmark completions comparing two Trie implementations against two sets
  of 25k and 170k words:

      ```sh
      mix trie.completions --benchmark "ag"
      ```

  """

  def run(args) do
    OptionParser.parse!(args, switches: [benchmark: :boolean])
    |> do_run

    :ok
  end

  #
  # PRIVATE
  #

  defp do_run({[], [prefix]}) do
    IO.puts("Loading 170k words dictionary...")

    dict = File.stream!("priv/assets/enable1.txt") |> Enum.into(Trie.A.new())

    IO.puts("Dictionary loaded!")

    completions = dict |> Trie.A.completions(prefix)

    IO.puts("Found #{length(completions)} complitions:")
    IO.inspect(completions)

    :ok
  end

  @files %{
    words25k: "priv/assets/popular.txt",
    words172k: "priv/assets/enable1.txt"
  }

  @benchee_opts time: 20,
                warmup: 5,
                memory_time: 10,
                profile_after: false,
                measure_function_call_overhead: true,
                formatters: [Benchee.Formatters.Console],
                print: %{
                  benchmarking: true,
                  fast_warning: true,
                  configuration: true
                }

  defp do_run({[{:benchmark, true}], [prefix]}) do
    IO.puts("Loading dictionaries...")

    dictionary_a_25k = File.stream!(@files[:words25k]) |> Enum.into(Trie.A.new())
    dictionary_a_170k = File.stream!(@files[:words172k]) |> Enum.into(Trie.A.new())
    dictionary_b_25k = File.stream!(@files[:words25k]) |> Enum.into(Trie.B.new())
    dictionary_b_170k = File.stream!(@files[:words172k]) |> Enum.into(Trie.B.new())
    dictionary_c_25k = File.stream!(@files[:words25k]) |> Enum.into(Trie.C.new())
    dictionary_c_170k = File.stream!(@files[:words172k]) |> Enum.into(Trie.C.new())

    spec = %{
      "Trie.A 25k" => fn ->
        Trie.A.completions(dictionary_a_25k, prefix)
      end,
      "Trie.A 170k" => fn ->
        Trie.A.completions(dictionary_a_170k, prefix)
      end,
      "Trie.B 25k" => fn ->
        Trie.B.completions(dictionary_b_25k, prefix)
      end,
      "Trie.B 170k" => fn ->
        Trie.B.completions(dictionary_b_170k, prefix)
      end,
      "Trie.C 25k" => fn ->
        Trie.C.completions(dictionary_c_25k, prefix)
      end,
      "Trie.C 170k" => fn ->
        Trie.C.completions(dictionary_c_170k, prefix)
      end
    }

    Benchee.run(spec, @benchee_opts)

    :ok
  end
end
