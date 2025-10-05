defmodule StatemTest do
  use ExUnit.Case
  doctest Statem

  test "greets the world" do
    assert Statem.hello() == :world
  end
end
