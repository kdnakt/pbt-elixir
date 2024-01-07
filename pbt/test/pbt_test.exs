defmodule PbtTest do
  use ExUnit.Case
  use PropCheck
  doctest Pbt

  property "always works" do
    forall type <- term() do
      boolean(type)
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

  def biggest([head | _tail]) do
    head
  end
end
