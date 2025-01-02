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
        let {{regular_items, regular_expected},
             {special_items, special_expected}} <-
              {regular_gen(price_list, special_list),
               special_gen(price_list, special_list)} do
          {Enum.shuffle(regular_items ++ special_items),
           regular_expected + special_expected, price_list, special_list}
        end
      end
    end
  end

  ## helpers
  defp bucket(n, unit) do
    div(n, unit) * unit
  end
end
