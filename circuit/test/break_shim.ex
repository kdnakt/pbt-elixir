defmodule BreakShim do
  @service :test_service

  def success() do
    :circuit_breaker.call(
      @service,
      fn -> :success end,
      :timer.hours(1),
      fn -> true end,
      :timer.hours(1),
      options()
    )
  end

  def err(reason) do
    :circuit_breaker.call(
      @service,
      fn -> {:error, reason} end,
      :timer.hours(1),
      fn -> true end,
      :timer.hours(1),
      options()
    )
  end

  def ignored_error(reason), do: err(reason)

  def timeout() do
    :circuit_breaker.call(
      @service,
      fn -> :timer.sleep(:infinity) end,
      0,
      fn -> true end,
      :timer.hours(1),
      options()
    )
  end

  defp options() do
    [
      n_error: 3,
      time_error: :timer.minutes(30),
      n_timeout: 3,
      time_timeout: :timer.minutes(30),
      n_call_timeout: 3,
      time_call_timeout: :timer.minutes(30),
      ignore_errors: [:ignore1, :ignore2]
    ]
  end
end
