defmodule Pbt do
  @moduledoc """
  Documentation for `Pbt`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Pbt.hello()
      :world

  """
  def hello do
    :world
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
