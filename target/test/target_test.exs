defmodule TargetTest do
  use ExUnit.Case
  use PropCheck

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
      result = Enum.reduce(p, {0, 0}, fn direction, {x, y} ->
        move(direction, {x, y})
      end)
      IO.inspect(result)
      true
    end
  end

  def path(), do: list(oneof([:left, :right, :up, :down]))

  def move(:left, {x, y}), do: {x-1, y}
  def move(:right, {x, y}), do: {x+1, y}
  def move(:up, {x, y}), do: {x, y+1}
  def move(:down, {x, y}), do: {x, y-1}
end
