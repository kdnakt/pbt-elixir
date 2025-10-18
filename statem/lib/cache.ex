defmodule Cache do
  use GenServer

  def start_link(n) do
    GenServer.start_link(__MODULE__, n, name: __MODULE__)
  end
  def stop() do
    GenServer.stop(__MODULE__)
  end

  def init(n) do
    :ets.new(:cache, [:public, :named_table])
    :ets.insert(:cache, {:count, 0, n})
    {:ok, :nostate}
  end

  def handle_call(_call, _from, state), do: {:noreply, state}
  def handle_cast(_cast, state), do: {:noreply, state}
  def handle_info(_msg, state), do: {:noreply, state}

  def find(key) do
    case :ets.match(:cache, {:_, {key, :"$1"}}) do
      [[val]] -> {:ok, val}
      [] -> {:error, :not_found}
    end
  end

  def cache(key, val) do
    case :ets.match(:cache, {:"$1", {key, :_}}) do
      [[n]] ->
        :ets.insert(:cache, {n, {key, val}})
      [] ->
        case :ets.lookup(:cache, :count) do
          [{:count, max, max}] ->
            :ets.insert(:cache, [{1, {key, val}}, {:count, 1, max}])
          [{:count, current, max}] ->
            :ets.insert(:cache, [
              {current + 1, {key, val}},
              {:count, current + 1, max}
            ])
        end
    end
  end

end
