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

  def word_count(chars) do
    stripped = :string.trim(dedupe_spaces(chars), :both, ' ')
    spaces = Enum.sum(for char <- stripped, char == ?\s, do: 1)

    case stripped do
      '' -> 0
      _ -> spaces + 1
    end
  end

  defp dedupe_spaces([]), do: []
  defp dedupe_spaces([?\s, ?\s | rest]), do: dedupe_spaces([?\s | rest])
  defp dedupe_spaces([h | t]), do: [h | dedupe_spaces(t)]

  property "word count" do
    forall chars <- non_empty(char_list()) do
      word_count(chars) == alt_word_count(chars)
    end
  end

  defp alt_word_count(string), do: space(to_charlist(string))
  defp space([]), do: 0
  defp space([?\s | str]), do: space(str)
  defp space(str), do: word(str)
  defp word([]), do: 1
  defp word([?\s | str]), do: 1 + space(str)
  defp word([_ | str]), do: word(str)
end
