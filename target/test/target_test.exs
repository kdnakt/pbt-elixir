defmodule TargetTest do
  use ExUnit.Case
  # cf.) https://github.com/ksaaskil/introduction-to-property-based-testing/blob/master/elixir-propcheck/test/tpbt_test.exs
  use PropCheck, default_opts: [numtests: 100, search_steps: 100]

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
end
