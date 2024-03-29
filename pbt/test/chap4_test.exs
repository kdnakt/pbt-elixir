defmodule Chap4 do
  use ExUnit.Case
  use PropCheck

  property "find all keys even though duplicated" do
    forall kv <- list({key(), val()}) do
      m = Map.new(kv)
      for {k,_v} <- kv, do: Map.fetch!(m, k)
      uniques =
        kv
          |> List.keysort(0)
          |> Enum.dedup_by(fn {x,_} -> x end)
      collect(true, {:dupes, to_range(5, length(kv) - length(uniques))})
    end
  end

  def key(), do: oneof([range(1,10), integer()])
  def val(), do: term()

  property "collect 1", [:verbose] do
    forall bin <- binary() do
      collect(is_binary(bin), byte_size(bin))
    end
  end

  property "collect 2", [:verbose] do
    forall bin <- binary() do
      collect(is_binary(bin), to_range(10, byte_size(bin)))
    end
  end

  def to_range(m, n) do
    base = div(n, m)
    {base * m, (base + 1) * m}
  end

  property "aggregate", [:verbose] do
    suits = [:club, :diamond, :heart, :space]

    forall hand <- vector(5, {oneof(suits), choose(1, 13)}) do
      # always pass
      aggregate(true, hand)
    end
  end

  property "test aggregate with false escape", [:verbose] do
    forall str <- utf8() do
        aggregate(escape(str), classes(str))
    end
  end

  defp escape(_), do: true

  def classes(str) do
    l = letters(str)
    n = numbers(str)
    p = punctuation(str)
    o = String.length(str) - (l+n+p)
    [{:letters, to_range(5, l)},
     {:numbers, to_range(5, n)},
     {:punctuation, to_range(5, p)},
     {:others, to_range(5, o)}]
  end

  def letters(str) do
    is_letter = fn c -> (c >= ?a && c <= ?z) || (c >= ?A && c <= ?Z) end
    length(for <<c::utf8 <- str>>, is_letter.(c), do: 1)
  end

  def numbers(str) do
    is_num = fn c -> c >= ?0 && c <= ?9 end
    length(for <<c::utf8 <- str>>, is_num.(c), do: 1)
  end

  def punctuation(str) do
    is_punctuation = fn c -> c in '.,;:\'"-' end
    length(for <<c::utf8 <- str>>, is_punctuation.(c), do: 1)
  end

  property "resize", [:verbose] do
    forall bin <- resize(150, binary()) do
      collect(is_binary(bin), to_range(10, byte_size(bin)))
    end
  end

  property "profile 1", [:verbose] do
    forall profile <- [
             name: resize(10, utf8()),
             age: pos_integer(),
             bio: resize(350, utf8())
           ] do
      name_len = to_range(10, String.length(profile[:name]))
      bio_len = to_range(300, String.length(profile[:bio]))
      aggregate(true, name: name_len, bio: bio_len)
    end
  end

  property "profile 2", [:verbose] do
    forall profile <- [
             name: utf8(),
             age: pos_integer(),
             bio: sized(s, resize(s * 35, utf8()))
           ] do
      name_len = to_range(10, String.length(profile[:name]))
      bio_len = to_range(300, String.length(profile[:bio]))
      aggregate(true, name: name_len, bio: bio_len)
    end
  end

  property "naive queue" do
    forall list <- list({term(), term()}) do
      q = :queue.from_list(list)
      :queue.is_queue(q)
    end
  end

  property "queue with let macro" do
    forall q <- queue() do
      :queue.is_queue(q)
    end
  end

  def queue() do
    let list <- list({term(), term()}) do
      :queue.from_list(list)
    end
  end

  property "non empty list" do
    forall list <- my_non_empty(list(term())) do
      Enum.count(list) != 0
    end
  end

  def my_non_empty(list_type) do
    such_that l <- list_type, when: l != [] and l != <<>>
  end

  property "non empty map" do
    forall map <- my_non_empty_map(map(term(), term())) do
      map_size(map) != 0
    end
  end

  def my_non_empty_map(gen) do
    such_that g <- gen, when: g != %{}
  end

  property "even and uneven" do
    forall {n, m} <- {my_even1(), my_uneven1()} do
      rem(n - m, 2) != 0
    end
  end

  def my_even1(), do: such_that n <- integer(), when: rem(n, 2) == 0
  def my_uneven1(), do: such_that n <- integer(), when: rem(n, 2) != 0

  property "even and uneven 2" do
    forall {n, m} <- {my_even2(), my_uneven2()} do
      rem(n - m, 2) != 0
    end
  end

  def my_even2(), do: let n <- integer(), do: n * 2
  def my_uneven2(), do: let n <- integer(), do: n * 2 + 1

end
