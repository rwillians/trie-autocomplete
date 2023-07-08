defmodule Trie do
  @moduledoc """
  The purpose of this Trie implementation is to solve autocompletion -- not
  auto correction, to be clear -- in a fast way. It's not the fastest, that
  would require using the primitives with which structs are made of in Elixir
  (tuples and lists), but it's a reasonably fast and readable implementation.

  No score/frequency has been assigned to words -- what could be used to rank
  most common higher. The results are sorted alphabetically.

  ## Usage

  The first thing you need to use this implementation is a set of words. You
  can add them to a root Trie node as follows:

      ```elixir
      root = Trie.new_root()
      root = Trie.put_words(root, ["Bite", "Bites", "Bird"])
      ```

  Once you have a root node with some words you can either ask for some
  completions or search the dictionary for words that start with the given
  prefix (case insensitive).

  Auto completion:

      ```elixir
      Trie.completions(root, "bit")
      # ["e", "es"]
      ```

  Search:

      ```elixir
      Trie.search(root, "bit")
      # ["Bite", "Bites"]
      ```

  ## Important

  Note that the public api interects exclusively with a Trie root node so that
  the entire dictionary of words is available. If you manually extract a child
  node and provide it to a public api call then an exception will be raised.

      ```elixir
      Trie.put_word(%Trie{key: "a"}, "apple")
      # ** (FunctionClauseError)
      ```

      ```elixir
      Trie.completions(%Trie{key: "a"}, "appl")
      # ** (FunctionClauseError)
      ```

      ```elixir
      Trie.search(%Trie{key: "a"}, "appl")
      # ** (FunctionClauseError)
      ```

  """

  import String, only: [downcase: 1, upcase: 1]

  @typedoc false
  @type t :: %Trie{
          key: String.t() | :root,
          end_of_word?: boolean,
          children: %{String.t() => t}
        }
  defstruct key: :root, end_of_word?: false, children: %{}

  @doc """
  Creates an empty dictionary (Trie root node).

      iex> Trie.new_root()
      %Trie{key: :root, end_of_word?: false, children: %{}}

  """
  @spec new_root() :: t
  def new_root, do: %Trie{}

  #

  @doc """
  Provides complitions for the given prefix (case insensitive) based on the
  given dictionary of words (Trie root node).

  ## Examples

  Only provides completions if the search term has at least 2 chars:

      iex> root = Trie.new_root() |> Trie.put_words(["Bite", "Bites", "Bird"])
      iex> Trie.completions(root, "b")
      []

  Provides completions for possible words:

      iex> root = Trie.new_root() |> Trie.put_words(["Bite", "Bites", "Bird"])
      iex> Trie.completions(root, "Bit")
      ["e", "es"]

  It's case insensitive:

      iex> root = Trie.new_root() |> Trie.put_words(["Bite", "Bites", "Bird"])
      iex> Trie.completions(root, "bi")
      ["rd", "te", "tes"]

      iex> root = Trie.new_root() |> Trie.put_words(["Bite", "Bites", "Bird"])
      iex> Trie.completions(root, "biTe")
      ["s"]

  """
  @spec completions(root_node :: t, prefix :: String.t()) :: [word :: String.t()]

  # matches if prefix has 2 or more chars
  def completions(%Trie{key: :root} = root, <<_, _, _::binary>> = prefix),
    do: get_node(root, prefix) |> get_completions()

  # fallback to not providing any suggestion
  def completions(%Trie{key: :root}, _prefix), do: []

  defp get_completions(node) do
    #                  ^ this node is a subtree
    get_children(node)
    |> with_prefix("")
    #             ^ we're gonna calculate words for the whole subtree
    #               and we don't care about the prefix that was typed,
    #               we just want to return the completions
    |> calculate_words
  end

  #

  @doc """
  Searches the given dictionary (Trie root node) for words starting with the
  given prefix.

  Same as {Trie.completions/2} but retruns the whole words.

  ## Examples

      iex> root = Trie.new_root() |> Trie.put_words(["Bite", "Bites", "Bird"])
      iex> Trie.search(root, "bi")
      ["bird", "bite", "bites"]

  """
  @spec search(root_node :: t, prefix :: String.t()) :: [word :: String.t()]

  def search(%Trie{key: :root} = root, <<_, _, _::binary>> = prefix),
    do: get_node(root, prefix) |> get_words(prefix)

  def search(%Trie{key: :root}, _prefix), do: []

  defp get_words(node, prefix) do
    get_children(node)
    |> with_prefix(prefix)
    #              ^ unlike completions, we want to return the whole words
    |> calculate_words
  end

  #

  @doc """
  Adds a word to the given Trie root node.

  ## Examples

      iex> Trie.new_root() |> Trie.put_word("Bite")
      %Trie{
        key: :root,
        end_of_word?: false,
        children: %{
          "B" => %Trie{
            key: "B",
            end_of_word?: false,
            children: %{
              "i" => %Trie{
                key: "i",
                end_of_word?: false,
                children: %{
                  "t" => %Trie{
                    key: "t",
                    end_of_word?: false,
                    children: %{
                      "e" => %Trie{
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
  def put_word(%Trie{key: :root} = t, ""), do: t

  def put_word(%Trie{key: :root} = t, <<_, _::binary>> = word),
    do: do_put_word(t, word)

  # string of chars given: take first char and put it into a node, repeat.
  defp do_put_word(node, <<head::utf8, tail::binary>> = _word) do
    key = to_key(head)
    child = get_node(node, key) || %Trie{key: key}
    child = do_put_word(child, tail)

    %{node | children: Map.put(node.children, key, child)}
  end

  # end of string of chars, that means this is the end of a word.
  defp do_put_word(node, ""), do: %{node | end_of_word?: true}

  #

  @doc """
  Same as {Trie.put_word/2} but for adding multiple words to the given Trie
  root node.

  ## Examples

      iex> Trie.put_words(%Trie{}, ["Bite", "Bites"])
      %Trie{
        key: :root,
        end_of_word?: false,
        children: %{
          "B" => %Trie{
            key: "B",
            end_of_word?: false,
            children: %{
              "i" => %Trie{
                key: "i",
                end_of_word?: false,
                children: %{
                  "t" => %Trie{
                    key: "t",
                    end_of_word?: false,
                    children: %{
                      "e" => %Trie{
                        key: "e",
                        end_of_word?: true,
                        children: %{
                          "s" => %Trie{
                            key: "s",
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
        }
      }

  """
  @spec put_words(Trie.t(), [String.t()]) :: Trie.t()
  def put_words(%Trie{key: :root} = t, []), do: t

  def put_words(%Trie{key: :root} = t, [_ | _] = words),
    do: Enum.reduce(words, t, &put_word(&2, &1))

  #
  # PRIVATE
  #

  # single char given, we can look for a child with it as index
  defp get_node(node, <<_::8>> = key) do
    children = node.children

    with nil <- Map.get(children, key),
         # ^ First we try to find the node with the casing the user typed
         nil <- Map.get(children, upcase(key)),
         # ^ If we don't find it, then we try to find with upcase
         #
         # | And only then we try to find with downcase.
         # | I know it looks weid, after all the only 2 possible options are
         # | up & down but here we have 3 cases here. The thing is, by doing
         # | it this weird way it's more likely that `downcase/1` won't get
         # | called, what saves us a couple nanoseconds.
         # ^
         do: Map.get(children, downcase(key))
  end

  # string with multiple chars: get the node for the fist char, repeat.
  defp get_node(node, <<char::utf8, rest::binary>>),
    do: get_node(node, to_key(char)) |> get_node(rest)

  #

  # function "signature" with default values
  defp with_prefix(nodes, prefix, acc \\ [])

  # Using tail recursion is more performant than using the {Enum.map/2}
  # funciton.
  #
  # Equivalent to:
  #
  #     Enum.map(nodes, fn node -> {node, prefix} end)
  #
  #     Enum.map(node, & {&1, prefix})
  #
  defp with_prefix([], _prefix, acc), do: :lists.reverse(acc)

  defp with_prefix([head | tail], prefix, acc),
    do: with_prefix(tail, prefix, [{head, prefix} | acc])

  #

  defp calculate_words(nodes_with_prefix, acc \\ [])

  defp calculate_words([{t, prefix} | tail], acc) do
    new_prefix = prefix <> t.key

    new_acc =
      if t.end_of_word?,
        do: [new_prefix | acc],
        else: acc

    get_children(t)
    |> with_prefix(new_prefix)
    |> append(tail)
    |> calculate_words(new_acc)
  end

  defp calculate_words([], acc), do: :lists.reverse(acc)

  #

  defp get_children(%Trie{} = t), do: :maps.values(t.children)

  defp to_key(char), do: :unicode.characters_to_binary([char])

  defp append(a, b), do: Enum.concat(a, b)
end

defimpl Collectable, for: Trie do
  def into(%Trie{key: :root} = root), do: {root, &collector/2}

  defp collector(root, {:cont, word}), do: Trie.put_word(root, String.trim(word))
  defp collector(root, :done), do: root
end
