defmodule ExerciseTest do
  use ExUnit.Case
  use PropCheck

  property "union of set" do
    forall {list_a, list_b} <- {list(number()), list(number())} do
      set_a = MapSet.new(list_a)
      set_b = MapSet.new(list_b)
      model_union = Enum.sort(MapSet.new(list_a ++ list_b))

      res =
        MapSet.union(set_a, set_b)
        |> MapSet.to_list()
        |> Enum.sort()

      res == model_union
    end
  end
end
