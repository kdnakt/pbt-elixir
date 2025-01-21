defmodule Checkout do
  @moduledoc """
  Documentation for `Checkout`.
  """

  def valid_price_list(list) do
    sorted = Enum.sort(list)
    length(list) == length(Enum.dedup_by(sorted, fn {x, _} -> x end))
  end

  def valid_special_list(list) do
    Enum.all?(list, fn {_, x, _} -> x != 0 end)
  end

  def total(item_list, price_list, specials) do
    if not valid_special_list(specials) do
      raise RuntimeError, message: "invalid list of specials"
    end

    counts = count_seen(item_list)
    {counts_left, prices} = apply_specials(counts, specials)
    prices + apply_regular(counts_left, price_list)
  end

  defp count_seen(item_list) do
    count = fn x -> x + 1 end

    Map.to_list(
      Enum.reduce(item_list, Map.new(), fn item, m ->
        Map.update(m, item, 1, count)
      end)
    )
  end

  defp apply_specials(items, specials) do
    Enum.map_reduce(items, 0, fn {name, count}, price ->
      case List.keyfind(specials, name, 0) do
        nil ->
          {{name, count}, price}

        {_, needed, value} ->
          {{name, rem(count, needed)},
            value * div(count, needed) + price}
      end
    end)
  end

  defp apply_regular(items, price_list) do
    Enum.sum(
      for {name, count} <- items do
        # {_, price} = List.keyfind(price_list, name, 0)
        # count * price
        count * cost_of_item(price_list, name)
      end
    )
  end

  defp cost_of_item(price_list, name) do
    case List.keyfind(price_list, name, 0) do
      nil ->
        raise RuntimeError, message: "unknown item:" + name
      {_, price} ->
        price
    end
  end
end
