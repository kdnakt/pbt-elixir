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

  property "dict merge" do
    forall {list_a, list_b} <-
             {list({term(), term()}), list({term(), term()})} do
      merged =
        Map.merge(Map.new(list_a), Map.new(list_b), fn _k,v1,_v2 -> v1 end)
      extract_keys(Enum.sort(Map.to_list(merged))) ==
        Enum.sort(Enum.uniq(extract_keys(list_a ++ list_b)))
    end
  end

  def extract_keys(list), do: for({k, _} <- list, do: k)
end
