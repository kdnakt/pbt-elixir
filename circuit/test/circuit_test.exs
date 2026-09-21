defmodule CircuitTest do
  use ExUnit.Case
  doctest Circuit

  test "greets the world" do
    assert Circuit.hello() == :world
  end
end
