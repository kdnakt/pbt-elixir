defmodule BookstoreTest do
  use ExUnit.Case
  doctest Bookstore
  use PropCheck
  use PropCheck.StateM

  test "greets the world" do
    assert Bookstore.hello() == :world
  end

  def title() do
    let s <- utf8() do
      elements([s, String.to_charlist(s)])
    end
  end

  def title(s) do
    elements(for {_,title,_,_,_} <- Map.values(s), do: partial(title))
  end

  def author() do
    let s <- utf8() do
      elements([s, String.to_charlist(s)])
    end
  end

  def author(s) do
    elements(for {_,_,author,_,_} <- Map.values(s), do: partial(author))
  end

  def partial(string) do
    string = IO.chardata_to_string(string)
    l = String.length(string)
    let {start, len} <- {range(0, l), non_neg_integer()} do
      String.slice(string, start, len)
    end
  end

  def isbn() do
    let isbn <- [
      oneof(["978", "979"]),
      let(x <- range(0, 9999), do: to_charlist(x)),
      let(x <- range(0, 9999), do: to_charlist(x)),
      let(x <- range(0, 999), do: to_charlist(x)),
      frequency([{10, [range(?0, ?9)]}, {1, ["X"]}])
    ] do
      to_string(Enum.join(isbn, "-"))
    end
  end

  def isbn(state), do: elements(Map.keys(state))

  def initial_state(), do: %{}

  def command(_state) do
    always_possible = [

      {:call, BookShim, :add_book_new, [isbn(), title(), author(), 1, 1]}
    ]

    relies_on_state = case Map.equal?(state, %{}) do
      true -> []
      false ->
        s = state
        [
          {:call, BookShim, :add_book_existing, [isbn(s), title(), author(), 1, 1]},
          {:call, BookShim, :add_copy_existing, [isbn(s)]},
          {:call, BookShim, :borrow_copy_avail, [isbn(s)]},
          {:call, BookShim, :borrow_copy_unavail, [isbn(s)]},
          {:call, BookShim, :borrow_copy_existing, [isbn(s)]},
          {:call, BookShim, :return_copy_existing, [isbn(s)]},
          {:call, BookShim, :return_copy_full, [isbn(s)]},
          {:call, BookShim, :find_book_by_author_existing, [author(s)]},
          {:call, BookShim, :find_book_by_title_existing, [title(s)]},
          {:call, BookShim, :find_book_by_isbn_existing, [isbn(s)]}
        ]
    end
    oneof(always_possible ++ relies_on_state)
  end

  def precondition(s, {:call, _mod, :add_book_new, [isbn|_]}) do
    not has_isbn(s, isbn)
  end
  def precondition(s, {:call, _mod, :add_copy_new, [isbn]}) do
    not has_isbn(s, isbn)
  end
  def precondition(s, {:call, _mod, :borrow_copy_unknown, [isbn]}) do
    not has_isbn(s, isbn)
  end
  def precondition(s, {:call, _mod, :return_copy_unknown, [isbn]}) do
    not has_isbn(s, isbn)
  end
  def precondition(s, {:call, _mod, :find_book_by_isbn_unknown, [isbn]}) do
    not has_isbn(s, isbn)
  end
  def precondition(s, {:call, _mod, :find_book_by_author_unknown, [auth]}) do
    not like_author(s, auth)
  end
  def precondition(s, {:call, _mod, :find_book_by_title_unknown, [title]}) do
    not like_title(s, title)
  end
  def precondition(s, {:call, _mod, :find_book_by_author_matching, [auth]}) do
    like_author(s, auth)
  end
  def precondition(s, {:call, _mod, :find_book_by_title_matching, [title]}) do
    like_title(s, title)
  end
  def precondition(s, {:call, _mod, _fun, [isbn|_]}) do
    has_isbn(s, isbn)
  end

  def postcondition(_state, {:call, _mod, _fun, _args}, _res) do
    true
  end

  def next_state(state, _res, {:call, _mod, _fun, _args}) do
    new_state = state
    new_state
  end

  def has_isbn?(map, isbn) do
    Map.has_key?(map, isbn)
  end

  def like_author?(map, author) do
    Enum.any?(Map.values(map), fn {_,_,a,_,_} -> contains?(a, author) end)
  end

  def like_title?(map, title) do
    Enum.any?(Map.values(map), fn {_,t,_,_,_} -> contains?(t, title) end)
  end

  defp contains?(string_or_chars_full, string_or_char_pattern) do
    string = IO.chardata_to_string(string_or_chars_full)
    pattern = IO.chardata_to_string(string_or_char_pattern)
    String.contains?(string, pattern)
  end
end
