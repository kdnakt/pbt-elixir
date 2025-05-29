defmodule TargetTest do
  use ExUnit.Case
  # cf.) https://github.com/ksaaskil/introduction-to-property-based-testing/blob/master/elixir-propcheck/test/tpbt_test.exs
  use PropCheck, default_opts: [numtests: 1000, search_steps: 100]

  property "always works" do
    forall type <- term() do
      boolean(type)
    end
  end

  def boolean(_) do
    true
  end

  property "path" do
    forall_targeted p <- path() do
      {x, y} = Enum.reduce(p, {0, 0}, fn direction, {x, y} ->
        move(direction, {x, y})
      end)
      neg_loss = x - y
      IO.puts("x: #{x}, y: #{y} neg_loss: #{neg_loss}")
      maximize(neg_loss)
      true
    end
  end

  def path(), do: list(oneof([:left, :right, :up, :down]))

  def move(:left, {x, y}), do: {x-1, y}
  def move(:right, {x, y}), do: {x+1, y}
  def move(:up, {x, y}), do: {x, y+1}
  def move(:down, {x, y}), do: {x, y-1}

  property "tree regular" do
    forall t <- tree() do
      weight = sides(t)
      IO.inspect(weight)
      true
    end
  end

  property "tree" do
    forall_targeted t <- tree() do
      weight = sides(t)
      {left, right} = weight
      IO.puts("left: #{left}, right: #{right}, weight:#{inspect(weight)}")
      maximize(left - right)
      true
    end
  end

  property "tree neighbor" do
    forall_targeted t <- user_nf(tree(), next_tree()) do
      weight = sides(t)
      {left, right} = weight
      IO.puts("left: #{left}, right: #{right}, weight:#{inspect(weight)}")
      maximize(left - right)
      true
    end
  end

  property "tree search" do
    forall l <- list(integer()) do
      not_exists t <- user_nf(let(x <- l, do: to_tree(x)), next_tree()) do
        {left, right} = sides(t)
        maximize(left - right)
        false # NOT_EXISTSがパスしないように
      end
    end
  end

  def next_tree() do
    fn old_tree, {_, t} ->
      let n <- integer() do
        insert(trunc(n * t * 100), old_tree)
      end
    end
  end

  def tree() do
    let l <- non_empty(list(integer())) do
      to_tree(l)
    end
  end

  def to_tree(list) do
    Enum.reduce(list, nil, fn x, acc ->
      insert(x, acc)
    end)
  end

  def insert(n, {:node, n, l, r}), do: {:node, n, l, r}
  def insert(n, {:node, m, l, r}) when n < m, do: {:node, m, insert(n, l), r}
  def insert(n, {:node, m, l, r}) when n > m, do: {:node, m, l, insert(n, r)}
  def insert(n, {:leaf, n}), do: {:leaf, n}
  def insert(n, {:leaf, m}) when n < m, do: {:node, n, nil, {:leaf, m}}
  def insert(n, {:leaf, m}) when n > m, do: {:node, n, {:leaf, m}, nil}
  def insert(n, nil), do: {:leaf, n}

  def sides({:node, _, l, r}) do
    {ll, lr} = sides(l)
    {rl, rr} = sides(r)
    {count_inner(l) + ll + lr, count_inner(r) + rl + rr}
  end
  def sides(_), do: {0, 0}

  def count_inner({:node, _, _, _}), do: 1
  def count_inner(_), do: 0

  property "example" do
    forall_targeted v <- user_nf(list(integer()), next_list()) do
      some_check(v)
    end
  end

  defp next_list() do
    fn prev_value, {depth, current_temperature} ->
      let(v <- some_generator(), do: modify(v, prev_value))
    end
  end
  # Mocked function for user_nf
  defp some_generator(), do: integer()
  defp modify(v, prev_value), do: v
  defp some_check(v), do: true

  # Quicksort
  def sort([]), do: []
  def sort([pivot|tail]) do
    first = for x <- tail, x < pivot, do: x
    second = for x <- tail, x >= pivot, do: x
    sort(first)
    ++ [pivot] ++
    sort(second)
  end

  property "quicksort time regular" do
    forall l <- my_list() do
      t0 = System.monotonic_time(:millisecond)
      sort(l)
      t1 = System.monotonic_time(:millisecond)
      t1 - t0 < 5000
    end
  end
  def my_list() do
    such_that l <- list(integer()), when: length(l) < 100000
  end

  property "mergesort time" do
    forall_targeted l <- user_nf(my_list(), next_list()) do
      t0 = System.monotonic_time(:millisecond)
      Enum.sort(l)
      t1 = System.monotonic_time(:millisecond)
      maximize(t1 - t0)
      t1 - t0 < 5000
    end
  end
end
