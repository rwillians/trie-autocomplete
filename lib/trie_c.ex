defmodule Trie.C do
  @moduledoc """
  Dictionary using Trie data structure implemented using tuples and maps.

  ## Usage

  Create a dictionary:

      ```elixir
      dict = Trie.C.new()
      ```
  Put words into the dictionary:

      ```elixir
      dict = Trie.C.put_words(dict, ["Bite", "Bites", "Bird"])
      ```

  Get completions:

      ```elixir
      Trie.C.completions(dict, "bit")
      # ["e", "es"]
      ```

  """

  import Enum, only: [concat: 2]
  import Map, only: [get: 2, put: 3]
  import String, only: [downcase: 1, upcase: 1]

  @typedoc false
  @type trie_node :: {char | :root, end_of_word? :: boolean, children :: %{char => trie_node}}

  @typedoc false
  @type t :: %Trie.C{root_node: trie_node}
  defstruct [:root_node]


  @doc """
  Creates an empty dictionary.

      iex> Trie.C.new()
      %Trie.C{root_node: {:root, false, %{}}}

  """
  @spec new() :: t
  def new, do: %Trie.C{root_node: {:root, false, %{}}}

  @doc """
  Provides completions for the given prefix (case insensitive).

  ## Examples

  Only provides completions if the search term has at least 2 chars:

      iex> Trie.C.new()
      iex> |> Trie.C.put_word("Bite")
      iex> |> Trie.C.put_word("Bites")
      iex> |> Trie.C.put_word("Bird")
      iex> |> Trie.C.completions("B")
      []

  Provides completions for known words:

      iex> Trie.C.new()
      iex> |> Trie.C.put_word("Bite")
      iex> |> Trie.C.put_word("Bites")
      iex> |> Trie.C.put_word("Bird")
      iex> |> Trie.C.completions("Bit")
      ["e", "es"]

  It's case insensitive:

      iex> Trie.C.new()
      iex> |> Trie.C.put_word("Bite")
      iex> |> Trie.C.put_word("Bites")
      iex> |> Trie.C.put_word("Bird")
      iex> |> Trie.C.completions("bi")
      ["rd", "te", "tes"]

      iex> Trie.C.new()
      iex> |> Trie.C.put_word("Bite")
      iex> |> Trie.C.put_word("Bites")
      iex> |> Trie.C.put_word("Bird")
      iex> |> Trie.C.completions("bItE")
      ["s"]

  """
  @spec completions(t, String.t()) :: [String.t()]
  def completions(%Trie.C{} = trie, <<_, _, _::binary>> = prefix) do
    find_or_create_node(trie.root_node, prefix)
    |> get_children
    |> pair_items_with("")
    #                  ^ we only want the suffix, we already know the prefix.
    |> calculate_words
  end

  def completions(%Trie.C{} = _trie, <<_::binary>>), do: []

  @doc """
  Put a word into the given dictionary.

      iex> Trie.C.new |> Trie.C.put_word("Bite")
      %Trie.C{
        root_node: {:root, false, %{
          66 => {66, false, %{
            105 => {105, false, %{
              116 => {116, false, %{
                101 => {101, true, %{}}
              }}
            }}
          }}
        }}
      }
  """
  @spec put_word(t, word :: String.t()) :: t
  def put_word(%Trie.C{} = trie, <<_, _, _::binary>> = word),
    do: %Trie.C{root_node: do_put_word(trie.root_node, word)}

  defp do_put_word({key, end_of_word?, children} = node, <<head::utf8, tail::binary>>) do
    child = find_or_create_node(node, <<head>>)
    child = do_put_word(child, tail)

    {key, end_of_word?, put(children, head, child)}
  end

  defp do_put_word({key, _, children}, <<>>), do: {key, true, children}

  #
  # PRIVATE
  #

  defp find_or_create_node({_key, _end_of_word, children}, <<char::utf8>> = str) do
    with nil <- get(children, char),
         <<up_char>> <- upcase(str),
         nil <- get(children, up_char),
         <<down_char>> <- downcase(str),
         nil <- get(children, down_char),
         do: {char, false, %{}}
  end

  defp find_or_create_node(node, <<head::utf8, tail::binary>>),
    do: find_or_create_node(node, <<head>>) |> find_or_create_node(tail)

  defp find_or_create_node(node, <<>>), do: node

  #

  defp get_children({_key, _end_of_word, children}), do: :maps.values(children)

  #

  defp pair_items_with(enum, value, acc \\ [])

  defp pair_items_with([head | tail], value, acc),
    do: pair_items_with(tail, value, [{head, value} | acc])

  defp pair_items_with([], _, acc), do: :lists.reverse(acc)

  #

  defp calculate_words(enum, acc \\ [])

  defp calculate_words([{{char, end_of_word?, _} = head, prefix} | tail], acc) do
    new_prefix = prefix <> :unicode.characters_to_binary([char])

    new_acc =
      if end_of_word?,
        do: [new_prefix | acc],
        else: acc

    get_children(head)
    |> pair_items_with(new_prefix)
    |> concat(tail)
    |> calculate_words(new_acc)
  end

  defp calculate_words([], acc), do: :lists.reverse(acc)
end

defimpl Collectable, for: Trie.C do
  import String, only: [trim: 1]
  import Trie.C, only: [put_word: 2]

  def into(%Trie.C{} = dict), do: {dict, &collector/2}

  defp collector(dict, {:cont, word}), do: put_word(dict, trim(word))
  defp collector(dict, :done), do: dict
end
