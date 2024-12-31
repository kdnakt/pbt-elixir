defmodule Checkout do
  @moduledoc """
  Documentation for `Checkout`.
  """

  def total(item_list, price_list, _specials) do
    Enum.sum(
      for item <- item_list do
        elem(List.keyfind(price_list, item, 0), 1)
      end
    )
  end
end
