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
end
