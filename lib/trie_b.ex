defmodule Trie.B do
  @moduledoc """
  Dictionary using Trie data structure implemented using struct and maps
  (integers as keys).

  ## Usage

  Create a dictionary:

      ```elixir
      dict = Trie.B.new()
      ```
  Put words into the dictionary:

      ```elixir
      dict = Trie.B.put_words(dict, ["Bite", "Bites", "Bird"])
      ```

  Get completions:

      ```elixir
      Trie.B.completions(dict, "bit")
      # ["e", "es"]
      ```
  """

  import Enum, only: [concat: 2]
  import Map, only: [get: 2, put: 3]
  import String, only: [downcase: 1, upcase: 1]

  @typedoc false
  @type t :: %Trie.B{
          key: String.t() | :root,
          end_of_word?: boolean,
          children: %{String.t() => t}
        }
  defstruct key: :root, end_of_word?: false, children: %{}

  @doc """
  Creates an empty dictionary (Trie root node).

      iex> Trie.B.new()
      %Trie.B{key: :root, end_of_word?: false, children: %{}}

  """
  @spec new() :: t
  def new, do: %Trie.B{}

  #

  @doc """
  Provides completions for the given prefix (case insensitive).

  ## Examples

  Only provides completions if the search term has at least 2 chars:

      iex> Trie.B.new()
      iex> |> Trie.B.put_word("Bite")
      iex> |> Trie.B.put_word("Bites")
      iex> |> Trie.B.put_word("Bird")
      iex> |> Trie.B.completions("B")
      []

  Provides completions for known words:

      iex> Trie.B.new()
      iex> |> Trie.B.put_word("Bite")
      iex> |> Trie.B.put_word("Bites")
      iex> |> Trie.B.put_word("Bird")
      iex> |> Trie.B.completions("Bit")
      ["e", "es"]

  It's case insensitive:

      iex> Trie.B.new()
      iex> |> Trie.B.put_word("Bite")
      iex> |> Trie.B.put_word("Bites")
      iex> |> Trie.B.put_word("Bird")
      iex> |> Trie.B.completions("bi")
      ["rd", "te", "tes"]

      iex> Trie.B.new()
      iex> |> Trie.B.put_word("Bite")
      iex> |> Trie.B.put_word("Bites")
      iex> |> Trie.B.put_word("Bird")
      iex> |> Trie.B.completions("bItE")
      ["s"]

  """
  @spec completions(dict_node :: t, prefix :: String.t()) :: [word :: String.t()]

  def completions(%Trie.B{key: :root} = dict, <<_, _, _::binary>> = prefix) do
    find_or_create_node(dict, prefix)
    |> get_children
    |> pair_items_with("")
    #                  ^ we only want the suffix, we already know the prefix.
    |> calculate_words
  end

  def completions(%Trie.B{key: :root}, _prefix), do: []

  #

  @doc """
  Adds a word to the given Trie dict node.

  ## Examples

      iex> Trie.B.new() |> Trie.B.put_word("Bite")
      %Trie.B{
        key: :root,
        end_of_word?: false,
        children: %{
          66 => %Trie.B{
            key: 66,
            end_of_word?: false,
            children: %{
              105 => %Trie.B{
                key: 105,
                end_of_word?: false,
                children: %{
                  116 => %Trie.B{
                    key: 116,
                    end_of_word?: false,
                    children: %{
                      101 => %Trie.B{
                        key: 101,
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
  def put_word(%Trie.B{key: :root} = t, ""), do: t

  def put_word(%Trie.B{key: :root} = t, <<_, _::binary>> = word),
    do: do_put_word(t, word)

  # string of chars given: take first char and put it into a node, repeat.
  defp do_put_word(node, <<head::utf8, tail::binary>> = _word) do
    child = find_or_create_node(node, <<head>>)
    child = do_put_word(child, tail)

    %{node | children: put(node.children, head, child)}
  end

  defp do_put_word(node, ""), do: %{node | end_of_word?: true}

  #
  # PRIVATE
  #

  defp find_or_create_node(node, <<char::utf8>> = str) do
    children = node.children

    with nil <- get(children, char),
         <<up_char>> <- upcase(str),
         nil <- get(children, up_char),
         <<down_char>> <- downcase(str),
         nil <- get(children, down_char),
         do: %Trie.B{key: char}
  end

  # string of multiple chars: get the node for the fist char, repeat.
  defp find_or_create_node(node, <<head::utf8, tail::binary>>),
    do: find_or_create_node(node, <<head>>) |> find_or_create_node(tail)

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
    new_prefix = prefix <> :unicode.characters_to_binary([t.key])

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

  defp get_children(t), do: :maps.values(t.children)

  defp append(a, b), do: concat(a, b)
end

defimpl Collectable, for: Trie.B do
  import String, only: [trim: 1]
  import Trie.B, only: [put_word: 2]

  def into(%Trie.B{key: :root} = dict), do: {dict, &collector/2}

  defp collector(dict, {:cont, word}), do: put_word(dict, trim(word))
  defp collector(dict, :done), do: dict
end
