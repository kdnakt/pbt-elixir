defmodule Checkout do
  @moduledoc """
  Documentation for `Checkout`.
  """

  def total(item_list, price_list, specials) do
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
        {_, price} = List.keyfind(price_list, name, 0)
        count * price
      end
    )
  end
end
