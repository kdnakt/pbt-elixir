defmodule CheckoutTest do
  use ExUnit.Case
  use PropCheck

  property "no special 1" do
    forall {item_list, expected_price, price_list} <- item_price_list() do
      expected_price == Checkout.total(item_list, price_list, [])
    end
  end

  property "no special (w/metrics)" do
    forall {item_list, expected_price, price_list} <- item_price_list() do
      (expected_price == Checkout.total(item_list, price_list, []))
      |> collect(bucket(length(item_list), 10))
    end
  end

  property "sum with special" do
    forall {items, expected_price, prices, specials}
           <- item_price_special() do
      expected_price == Checkout.total(items, prices, specials)
    end
  end

  property "negative testing for expected results" do
    forall {items, prices, specials} <- lax_lists() do
      collect(item_list_type(items, prices),
        try do
          is_integer(Checkout.total(items, prices, specials))
        rescue
          e in [RuntimeError] ->
            e.message == "invalid list of specials" ||
              e.message == "invalid list of prices" ||
              String.starts_with?(e.message, "unknown item:")
          _ ->
            false
        end)
    end
  end

  property "duplicated list" do
    forall price_list <- dupe_list() do
      false == Checkout.valid_price_list(price_list)
    end
  end

  property "dupe special list" do
    forall special_list <- dupe_special_list() do
      false == Checkout.valid_special_list(special_list)
    end
  end

  ## generators
  defp item_price_list() do
    let price_list <- price_list() do
      let {item_list, expected_price} <- item_list(price_list) do
        {item_list, expected_price, price_list}
      end
    end
  end

  defp price_list() do
    let price_list <- non_empty(list({non_empty(utf8()), integer()})) do
      sorted = Enum.sort(price_list)
      Enum.dedup_by(sorted, fn {x, _} -> x end)
    end
  end

  defp item_list(price_list) do
    sized(size, item_list(size, price_list, {[], 0}))
  end

  defp item_list(0, _, acc), do: acc
  defp item_list(n, price_list, {item_acc, price_acc}) do
    let {item, price} <- elements(price_list) do
      item_list(n - 1, price_list, {[item | item_acc], price + price_acc})
    end
  end

  defp item_price_special() do
    let price_list <- price_list() do
      let special_list <- special_list(price_list) do
        let {items, price} <-
            (let_shrink([
                {regular_items, regular_expected} <-
                  regular_gen(price_list, special_list),
                {special_items, special_expected} <-
                  special_gen(price_list, special_list)
              ]) do
                {regular_items ++ special_items,
                 regular_expected + special_expected}
              end) do
          {items, price, price_list, special_list}
        end
      end
    end
  end

  defp special_list(price_list) do
    items = for {name, _} <- price_list, do: name

    let specials <- list({elements(items), choose(2, 5), integer()}) do
      sorted = Enum.sort(specials)
      Enum.dedup_by(sorted, fn {x, _, _} -> x end)
    end
  end

  defp regular_gen(price_list, special_list) do
    regular_gen(price_list, special_list, [], 0)
  end

  defp regular_gen([], _, list, price), do: {list, price}
  defp regular_gen([{item, cost} | prices], specials, items, price) do
    count_gen =
      case List.keyfind(specials, item, 0) do
        {_, limit, _} -> choose(0, limit - 1)
        _ -> non_neg_integer()
      end

    let count <- count_gen do
      regular_gen(
        prices,
        specials,
        let(v <- vector(count, item), do: v ++ items),
        cost * count + price
      )
    end
  end

  defp special_gen(_, special_list) do
    special_gen(special_list, [], 0)
  end

  defp special_gen([], items, price), do: {items, price}
  defp special_gen([{item, count, cost} | specials], items, price) do
    let multiplier <- non_neg_integer() do
      special_gen(
        specials,
        let(v <- vector(count * multiplier, item), do: v ++ items),
        cost * multiplier + price
      )
    end
  end

  defp dupe_list() do
    let items <- non_empty(list(utf8())) do
      vector(length(items) + 1, {elements(items), integer()})
    end
  end

  defp dupe_special_list() do
    let items <- non_empty(list(utf8())) do
      vector(length(items) + 1, {elements(items), integer(), integer()})
    end
  end

  ## helpers
  defp bucket(n, unit) do
    div(n, unit) * unit
  end

  defp lax_lists() do
    known_items = ["A", "B", "C"]
    maybe_known_item_gen = elements(known_items ++ [utf8()])

    {list(maybe_known_item_gen),
     list({maybe_known_item_gen, integer()}),
     list({maybe_known_item_gen, integer(), integer()})}
  end

  defp item_list_type(items, prices) do
    Enum.all?(items, fn x -> has_price(x, prices) end)
  end

  defp has_price(item, prices) do
    case List.keyfind(prices, item, 0) do
      nil -> false
      _ -> true
    end
  end
end
