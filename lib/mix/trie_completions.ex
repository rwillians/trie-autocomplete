defmodule Mix.Tasks.Trie.Completions do
  @moduledoc """
  Provides completions for the given prefix (case insensitve) based on the
  compiled dictionary of words (25k+ English words).

  Get completions for a given prefix:

      ```
      mix trie.completions "ag"
      ```

  Benchmark completions for a given prefix:

        ```
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
    Trie.Bench.get_dictionary()
    |> Trie.completions(prefix)
    |> IO.inspect()
  end

  defp do_run({[{:benchmark, true}], [prefix]}) do
    Trie.Bench.completions(prefix)
  end
end
