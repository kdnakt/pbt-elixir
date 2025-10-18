defmodule CacheTest do
  use ExUnit.Case
  use PropCheck
  use PropCheck.StateM
  doctest Cache
  @moduletag timeout: :infinity

  @cache_size 10

  property "stateful property", [:verbose] do
    forall cmds <- commands(__MODULE__) do
      Cache.start_link(@cache_size)
      {history, state, result} = run_commands(__MODULE__, cmds)
      Cache.stop()

      (result == :ok)
      |> aggregate(command_names(cmds))
      |> when_fail(
        IO.puts("""
        History: #{inspect(history, pretty: true)}
        State: #{inspect(state, pretty: true)}
        Result: #{inspect(result, pretty: true)}
        """)
      )
    end
  end

  defmodule State do
    @cache_size 10
    defstruct max: @cache_size, count: 0, entries: []
  end
  def initial_state(), do: %State{}

  def command(_state) do
    frequency([
      {1, {:call, Cache, :find, [key()]}},
      {3, {:call, Cache, :cache, [key(), val()]}},
      {1, {:call, Cache, :flush, []}}
    ])
  end

  def precondition(%State{count: 0}, {:call, Cache, :flush, []}) do
    false
  end

  def precondition(%State{}, {:call, _mod, _fun, _args}) do
    true
  end

  def key() do
    oneof([range(1, @cache_size), integer()])
  end

  def val() do
    integer()
  end

  def next_state(state, _res, {:call, Cache, :flush, _}) do
    %{state | count: 0, entries: []}
  end

  def next_state(
      s = %State{entries: l, count: n, max: m},
      _res,
      {:call, Cache, :cache, [k, v]}
      ) do
    case List.keyfind(l, k, 0) do
      nil when n == m ->
        %{s | entries: tl(l) ++ [{k, v}]}
      nil when n < m ->
        %{s | entries: l ++ [{k, v}], count: n + 1}
      {fik, _} ->
        %{s | entries: List.keyreplace(l, k, 0, {k, v})}
    end
  end

  def next_state(state, _res, {:call, Cache, _fun, _args}) do
    state
  end

  def postcondition(%State{entries: l}, {:call, _, :find, [key]}, res) do
    case List.keyfind(l, key, 0) do
      nil -> res == {:error, :not_found}
      {fikey, val} -> res == {:ok, val}
    end
  end

  def postcondition(_state, {:call, _mod, _fun, _args}, _res) do
    true
  end
end
