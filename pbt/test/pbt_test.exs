defmodule PbtTest do
  use ExUnit.Case
  use PropCheck
  doctest Pbt

  property "always works" do
    forall type <- term() do
      boolean(type)
    end
  end

  property "Pbt: find max item" do
    forall x <- non_empty(list(integer())) do
      Pbt.biggest(x) == model_biggest(x)
    end
  end

  def model_biggest(list) do
    List.last(Enum.sort(list))
  end

  property "Find last" do
    forall {list, known_last} <- {list(number()), number()} do
      known_list = list ++ [known_last]
      known_last == List.last(known_list)
    end
  end

  property "find max item" do
    forall x <- non_empty(list(integer())) do
      biggest(x) == List.last(Enum.sort(x))
    end
  end

  def boolean(_) do
    true
  end

  def biggest([head | tail]) do
    biggest(tail, head)
  end

  defp biggest([], max) do
    max
  end

  defp biggest([head | tail], max) when head >= max do
    biggest(tail, head)
  end

  defp biggest([head | tail], max) when head < max do
    biggest(tail, max)
  end

  property "sorted list has ordered pair" do
    forall list <- list(term()) do
      is_ordered(Enum.sort(list))
    end
  end

  def is_ordered([a, b | t]) do
    a <= b and is_ordered([b | t])
  end

  def is_ordered(_) do
    true
  end

  property "sorted list has the same size as before" do
    forall l <- list(number()) do
      length(l) == length(Enum.sort(l))
    end
  end

  property "no items added" do
    forall l <- list(number()) do
      sorted = Enum.sort(l)
      Enum.all?(sorted, fn elem -> elem in l end)
    end
  end

  property "no items removed" do
    forall l <- list(number()) do
      sorted = Enum.sort(l)
      Enum.all?(l, fn elem -> elem in sorted end)
    end
  end

  def strdatetime() do
    let(date_time <- datetime(), do: to_str(date_time))
  end

  def datetime() do
    {date(), time(), timezone()}
  end

  def date() do
    such_that(
      {y, m, d} <- {year(), month(), day()},
      when: :calendar.valid_date(y, m, d)
    )
  end

  def year() do
    shrink(range(0, 9999), [range(1970, 2000), range(1900, 2100)])
  end

  def month(), do: range(1, 12)

  def day(), do: range(1, 31)

  def time(), do: {range(0, 24), range(0, 59), range(0, 60)}

  def timezone() do
    {elements([:+, :-]), shrink(range(0, 99), [range(0, 14), 0]),
     shrink(range(0, 99), [0, 15, 30, 45])}
  end

  def to_str({{y, m, d}, {h, mi, s}, {sign, ho, mo}}) do
    format_str = "~4..0b-~2..0b-~2..0bT~2..0b:~2..0b:~2..0b~s~2..0b:~2..0b"
    :io_lib.format(format_str, [y, m, d, h, mi, s, sign, ho, mo])
    |> to_string()
  end

  def tree(n) when n <= 1 do
    {:leaf, number()}
  end

  def tree(n) do
    per_branch = div(n, 2)
    {:branch, tree(per_branch), tree(per_branch)}
  end

  def tree_shrink(n) when n <= 1 do
    {:leaf, number()}
  end

  def tree_shrink(n) do
    per_branch = div(n, 2)

    let_shrink([
      left <- tree_shrink(per_branch),
      right <- tree_shrink(per_branch)
    ]) do
      {:branch, left, right}
    end
  end

  property "dairy" do
    forall food <- meal() do
      dairy_count(food) == 0
    end
  end

  def meal() do
    let_shrink([
      appetizer <- [elements([:soup, :salad, :cheesesticks])],
      drink <- [elements([:water, :soda, :milk])],
      entree <- [elements([:steak, :chicken, :lasagna])],
      dessert <- [elements([:cake, :icecream, :pie])]
    ]) do
      appetizer ++ drink ++ entree ++ dessert
    end
  end

  def dairy_count(list) do
    length(
      Enum.filter(list, fn
        :milk -> true
        :cheesesticks -> true
        :icecream -> true
        :lasagna -> true
        _ -> false
      end)
    )
  end
end
