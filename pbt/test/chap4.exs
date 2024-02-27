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

  def key(), do: integer()
  def val(), do: term()

  property "collect 1", [:verbose] do
    forall bin <- binary() do
      collect(is_binary(bin), byte_size(bin))
    end
  end

  property "collect 2", [:verbose] do
    forall bin <- binary() do
      collect(is_binary(bin), to_range(10, byte_size()))
    end
  end

  def to_range(m, n) do
    base = div(n, m)
    {base * m, (base + 1) * m}
  end

end
