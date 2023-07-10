defmodule Trie.MemOptimized do
  @moduledoc false

  import Enum, only: [concat: 2]
  import Map, only: [get: 2, put: 3]
  import String, only: [downcase: 1, trim: 1, upcase: 1]

  @typedoc false
  @type t :: {char | :dict, end_of_word? :: boolean, children :: map}
  
  @doc """
  Creates an empty dictionary.
  """
  @spec new() :: t
  def new, do: {:dict, false, %{}}

  @doc """
  Given a prefix, returns completions of words from the given dictionary.
  """
  @spec completions(t, String.t()) :: [String.t()]
  def completions({:dict, _, _} = root, <<_, _, _::binary>> = prefix) do
    find_or_create_node(root, prefix) 
    |> get_children
    |> pair_items_with("")
    |> calculate_words
  end

  @doc """
  Put a word into the given dictionary.
  """
  @spec put_word(t, word :: String.t()) :: t
  def put_word({:dict, false, _} = root, <<_, _, _::binary>> = word),
    do: do_put_word(root, word)

  defp do_put_word({key, end_of_word?, children} = node, <<head::utf8, tail::binary>>) do
    child = find_or_create_node(node, <<head>>)
    child = do_put_word(child, tail)
   
    {key, end_of_word?, put(children, head, child)}
  end

  defp do_put_word({key, _, children}, <<>>), do: {key, true, children}

  @doc """
  Collect (`Enum.into/3`) words into a dictionary.
  """
  def into({:dict, _, _} = dict, word), do: put_word(dict, trim(word))

  #
  # PRIVATE
  #

  defp find_or_create_node({_key, _end_of_word, children}, <<char::utf8>> = char_binary) do
    with nil <- get(children, char),
         <<char>> <- upcase(char_binary),
         nil <- get(children, char),
         <<char>> <- downcase(char_binary),
         nil <- get(children, char),
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
    new_prefix = prefix <> :erlang.iolist_to_binary([char])

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

