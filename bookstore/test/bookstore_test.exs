defmodule BookstoreTest do
  use ExUnit.Case
  doctest Bookstore
  use PropCheck
  use PropCheck.StateM

  test "greets the world" do
    assert Bookstore.hello() == :world
  end

  property "bookstore state machine", [:verbose] do
    property_setup(
      fn ->
        {:ok, apps} = Application.ensure_all_started(:bookstore)
        fn ->
          Enum.each(apps, &Application.stop/1)
          :ok
        end
      end,
      forall cmds <- commands(__MODULE__) do
        Bookstore.DB.setup()
        {history, state, result} = run_commands(__MODULE__, cmds)
        Bookstore.DB.teardown()

        (result == :ok)
        |> aggregate(command_names(cmds))
        |> when_fail(
          IO.puts("""
          History: #{inspect(history)}
          State: #{inspect(state)}
          Result: #{inspect(result)}
          """)
        )
      end
    )
  end

  def title(), do: friendly_unicode()

  def title(s) do
    elements(for {_,title,_,_,_} <- Map.values(s), do: partial(title))
  end

  def author(), do: friendly_unicode()

  def author(s) do
    elements(for {_,_,author,_,_} <- Map.values(s), do: partial(author))
  end

  def friendly_unicode() do
    bad_chars = [<<0>>, "\\", "_", "%"]
    friendly_gen =
      such_that s <- utf8(), when: (not contains_any?(s, bad_chars)) &&
        String.length(s) < 256
    let x <- friendly_gen do
      elements([x, String.to_charlist(x)])
    end
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

  def command(state) do
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
  def precondition(s, {:call, _, :borrow_copy_avail, [isbn]}) do
    0 < elem(Map.get(s, isbn, {:fake, :fake, :fake, :fake, 0}), 4)
  end
  def precondition(s, {:call, _, :borrow_copy_unavail, [isbn]}) do
    0 == elem(Map.get(s, isbn, {:fake, :fake, :fake, :fake, 1}), 4)
  end
  def precondition(s, {:call, _, :return_copy_full, [isbn]}) do
    {_, _, _, owned, avail} = Map.get(s, isbn, {:fake, :fake, :fake, 0, 0})
    avail == owned && owned != 0
  end
  def precondition(s, {:call, _, :return_copy_existing, [isbn]}) do
    {_, _, _, owned, avail} = Map.get(s, isbn, {:fake, :fake, :fake, 0, 0})
    avail != owned && owned != 0
  end
  def precondition(s, {:call, _mod, _fun, [isbn|_]}) do
    has_isbn(s, isbn)
  end

  def postcondition(_, {_, _, :add_book_new, _}, :ok) do
    true
  end
  def postcondition(_, {_, _, :add_book_existing, _}, {:error, _}) do
    true
  end
  def postcondition(_, {_, _, :add_copy_existing, _}, :ok) do
    true
  end
  def postcondition(_, {_, _, :add_copy_new, _}, {:error, :not_found}) do
    true
  end
  def postcondition(_, {_, _, :borrow_copy_avail, _}, :ok) do
    true
  end
  def postcondition(_, {_, _, :borrow_copy_unavail, _}, {:error, :unavailable}) do
    true
  end
  def postcondition(_, {_, _, :borrow_copy_unknown, _}, {:error, :not_found}) do
    true
  end
  def postcondition(_, {_, _, :return_copy_full, _}, {:error, _}) do
    true
  end
  def postcondition(_, {_, _, :return_copy_existing, _}, :ok) do
    true
  end
  def postcondition(_, {_, _, :return_copy_unknown, _}, {:error, :not_found}) do
    true
  end
  def postcondition(s, {_, _, :find_book_by_isbn_exists, [isbn]}, {:ok, [res]}) do
    book_equal(res, Map.get(s, isbn, nil))
  end
  def postcondition(_, {_, _, :find_book_by_isbn_unknown, _}, {:ok, []}) do
    true
  end
  def postcondition(state, {_, _, :find_book_by_author_matching, [auth]}, {:ok, res}) do
    map = :maps.filter(fn _, {_,_,a,_,_} -> contains?(a, auth) end, state)
    books_equal(Enum.sort(res), Enum.sort(Map.values(map)))
  end
  def postcondition(_, {_, _, :find_book_by_author_unknown, _}, {:ok, []}) do
    true
  end
  def postcondition(state, {_, _, :find_book_by_title_matching, [title]}, {:ok, res}) do
    map = :maps.filter(fn _, {_,t,_,_,_} -> contains?(t, title) end, state)
    books_equal(Enum.sort(res), Enum.sort(Map.values(map)))
  end
  def postcondition(_, {_, _, :find_book_by_title_unknown, _}, {:ok, []}) do
    true
  end
  def postcondition(_state, {:call, mod, fun, args}, res) do
    mod = inspect(mod)
    fun = inspect(fun)
    args = inspect(args)
    res = inspect(res)
    IO.puts(
      "\nnon-matching postcondition: {#{mod}, #{fun}, #{args}} -> #{res}"
    )
    false
  end

  def next_state(
    state,
    _,
    {:call, _, :add_book_new, [isbn, title, author, total, avail]}
  ) do
    Map.put(state, isbn, {isbn, title, author, total, avail})
  end
  def next_state(state, _, {:call, _, :add_copy_existing, [isbn]}) do
    {isbn, title, author, owned, avail} = state[isbn]
    Map.put(state, isbn, {isbn, title, author, owned + 1, avail + 1})
  end
  def next_state(state, _, {:call, _, :borrow_copy_avail, [isbn]}) do
    {isbn, title, author, owned, avail} = state[isbn]
    Map.put(state, isbn, {isbn, title, author, owned, avail - 1})
  end
  def next_state(state, _, {:call, _, :return_copy_existing, [isbn]}) do
    {isbn, title, author, owned, avail} = state[isbn]
    Map.put(state, isbn, {isbn, title, author, owned, avail + 1})
  end
  def next_state(state, _res, {:call, _mod, _fun, _args}) do
    new_state = state
    new_state
  end

  def has_isbn(map, isbn) do
    Map.has_key?(map, isbn)
  end

  def like_author(map, author) do
    Enum.any?(Map.values(map), fn {_,_,a,_,_} -> contains?(a, author) end)
  end

  def like_title(map, title) do
    Enum.any?(Map.values(map), fn {_,t,_,_,_} -> contains?(t, title) end)
  end

  defp contains?(string_or_chars_full, string_or_char_pattern) do
    string = IO.chardata_to_string(string_or_chars_full)
    pattern = IO.chardata_to_string(string_or_char_pattern)
    String.contains?(string, pattern)
  end

  defp contains_any?(string_or_chars_full, patterns) do
    Enum.any?(patterns, &contains?(string_or_chars_full, &1))
  end

  defp books_equal([], []) do
    true
  end
  defp books_equal([a | as], [b | bs]) do
    book_equal(a, b) && books_equal(as, bs)
  end
  defp books_equal(_, _) do
    false
  end

  defp book_equal(
    {isbn_a, title_a, author_a, owned_a, avail_a},
    {isbn_b, title_b, author_b, owned_b, avail_b}
  ) do
    {isbn_a, title_a, avail_a} == {isbn_b, title_b, avail_b} &&
      String.equivalent?(
        IO.chardata_to_string(title_a),
        IO.chardata_to_string(title_b)
      ) &&
      String.equivalent?(
        IO.chardata_to_string(author_a),
        IO.chardata_to_string(author_b)
      )
  end
end
