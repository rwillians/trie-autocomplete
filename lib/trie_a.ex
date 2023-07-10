defmodule Trie.A do
  @moduledoc """
  Dictionary using Trie data structure implemented using struct and maps
  (binary single-char string as keys).

  ## Usage

  Create a dictionary:

      ```elixir
      dict = Trie.A.new()
      ```
  Put words into the dictionary:

      ```elixir
      dict = Trie.A.put_words(dict, ["Bite", "Bites", "Bird"])
      ```

  Get completions:

      ```elixir
      Trie.A.completions(dict, "bit")
      # ["e", "es"]
      ```
  """

  import Enum, only: [concat: 2]
  import Map, only: [get: 2]
  import String, only: [downcase: 1, upcase: 1]

  @typedoc false
  @type t :: %Trie.A{
          key: String.t() | :root,
          end_of_word?: boolean,
          children: %{String.t() => t}
        }
  defstruct key: :root, end_of_word?: false, children: %{}

  @doc """
  Creates an empty dictionary (Trie root node).

      iex> Trie.A.new()
      %Trie.A{key: :root, end_of_word?: false, children: %{}}

  """
  @spec new() :: t
  def new, do: %Trie.A{}

  #

  @doc """
  Provides completions for the given prefix (case insensitive).

  ## Examples

  Only provides completions if the search term has at least 2 chars:

      iex> Trie.A.new()
      iex> |> Trie.A.put_word("Bite")
      iex> |> Trie.A.put_word("Bites")
      iex> |> Trie.A.put_word("Bird")
      iex> |> Trie.A.completions("B")
      []

  Provides completions for known words:

      iex> Trie.A.new()
      iex> |> Trie.A.put_word("Bite")
      iex> |> Trie.A.put_word("Bites")
      iex> |> Trie.A.put_word("Bird")
      iex> |> Trie.A.completions("Bit")
      ["e", "es"]

  It's case insensitive:

      iex> Trie.A.new()
      iex> |> Trie.A.put_word("Bite")
      iex> |> Trie.A.put_word("Bites")
      iex> |> Trie.A.put_word("Bird")
      iex> |> Trie.A.completions("bi")
      ["rd", "te", "tes"]

      iex> Trie.A.new()
      iex> |> Trie.A.put_word("Bite")
      iex> |> Trie.A.put_word("Bites")
      iex> |> Trie.A.put_word("Bird")
      iex> |> Trie.A.completions("bItE")
      ["s"]

  """
  @spec completions(dict_node :: t, prefix :: String.t()) :: [word :: String.t()]

  def completions(%Trie.A{key: :root} = dict, <<_, _, _::binary>> = prefix) do
    get_node(dict, prefix)
    |> get_children
    |> pair_items_with("")
    #                  ^ we only want the suffix, we already know the prefix.
    |> calculate_words
  end

  def completions(%Trie.A{key: :root}, _prefix), do: []

  #

  @doc """
  Adds a word to the given Trie dict node.

  ## Examples

      iex> Trie.A.new() |> Trie.A.put_word("Bite")
      %Trie.A{
        key: :root,
        end_of_word?: false,
        children: %{
          "B" => %Trie.A{
            key: "B",
            end_of_word?: false,
            children: %{
              "i" => %Trie.A{
                key: "i",
                end_of_word?: false,
                children: %{
                  "t" => %Trie.A{
                    key: "t",
                    end_of_word?: false,
                    children: %{
                      "e" => %Trie.A{
                        key: "e",
                        end_of_word?: true,
                        children: %{}
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
  """
  @spec put_word(t, String.t()) :: t
  def put_word(%Trie.A{key: :root} = t, ""), do: t

  def put_word(%Trie.A{key: :root} = t, <<_, _::binary>> = word),
    do: do_put_word(t, word)

  # string of chars given: take first char and put it into a node, repeat.
  defp do_put_word(node, <<head::utf8, tail::binary>> = _word) do
    key = to_key(head)

    child = get_node(node, key) || %Trie.A{key: key}
    child = do_put_word(child, tail)

    %{node | children: Map.put(node.children, key, child)}
  end

  defp do_put_word(node, ""), do: %{node | end_of_word?: true}

  #
  # PRIVATE
  #

  # single char given, we can look for a child with it as index
  defp get_node(node, <<_::8>> = key) do
    children = node.children

    with nil <- get(children, key),
         # ^ First we try to find the node with the casing the user typed
         nil <- get(children, upcase(key)),
         # ^ If we don't find it, then we try to find with upcase
         #
         # | And only then we try to find with downcase.
         # | I know it looks weid, after all the only 2 possible options are
         # | up & down but here we have 3 cases here. The thing is, by doing
         # | it this weird way it's more likely that `downcase/1` won't get
         # | called, what saves us a couple nanoseconds.
         # ^
         do: get(children, downcase(key))
  end

  # string of multiple chars: get the node for the fist char, repeat.
  defp get_node(node, <<char::utf8, rest::binary>>),
    do: get_node(node, to_key(char)) |> get_node(rest)

  #

  defp pair_items_with(nodes, prefix, acc \\ [])

  # Using tail recursion is more performant than using the {Enum.map/2}
  # funciton.
  #
  # Equivalent to:
  #
  #     Enum.map(nodes, fn node -> {node, prefix} end)
  #
  #     Enum.map(node, & {&1, prefix})
  #
  defp pair_items_with([], _prefix, acc), do: :lists.reverse(acc)

  defp pair_items_with([head | tail], prefix, acc),
    do: pair_items_with(tail, prefix, [{head, prefix} | acc])

  #

  defp calculate_words(nodes_pair_items_with, acc \\ [])

  defp calculate_words([{t, prefix} | tail], acc) do
    new_prefix = prefix <> t.key

    new_acc =
      if t.end_of_word?,
        do: [new_prefix | acc],
        else: acc

    get_children(t)
    |> pair_items_with(new_prefix)
    |> append(tail)
    |> calculate_words(new_acc)
  end

  defp calculate_words([], acc), do: :lists.reverse(acc)

  #

  defp get_children(%Trie.A{} = t), do: :maps.values(t.children)

  defp to_key(char), do: :unicode.characters_to_binary([char])

  defp append(a, b), do: concat(a, b)
end

defimpl Collectable, for: Trie.A do
  import String, only: [trim: 1]
  import Trie.A, only: [put_word: 2]

  def into(%Trie.A{key: :root} = dict), do: {dict, &collector/2}

  defp collector(dict, {:cont, word}), do: put_word(dict, trim(word))
  defp collector(dict, :done), do: dict
end
