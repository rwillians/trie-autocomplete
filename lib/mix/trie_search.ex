defmodule Mix.Tasks.Trie.Search do
  @moduledoc """
  Search the compiled dictionary of words (25k+ English words) by a given
  prefix.

  Search words started with prefix:

      ```
      mix trie.search "ad"
      ```

  Benchmark a search prefix:

        ```
        mix trie.search --benchmark "ad"
        ```
  """

  def run(args) do
    OptionParser.parse!(args, switches: [benchmark: :boolean])
    |> do_run

    :ok
  end

  #
  # Private
  #

  defp do_run({[], [prefix]}) do
    Trie.Bench.get_dictionary()
    |> Trie.search(prefix)
    |> IO.inspect()
  end

  defp do_run({[{:benchmark, true}], [prefix]}) do
    Trie.Bench.search(prefix)
  end
end
