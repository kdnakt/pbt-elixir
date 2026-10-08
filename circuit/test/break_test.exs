defmodule BreakTest do
  use ExUnit.Case
  use PropCheck
  use PropCheck.FSM

  property "FSM property for circuit breaker", [:verbose] do
    Application.stop(:circuit_breaker)
    forall cmds <- commands(__MODULE__) do
      {:ok, pid} = :circuit_breaker.start_link()
      {history, state, result} = run_commands(__MODULE__, cmds)
      GenServer.stop(pid, :normal, 5000)

      (result == :ok)
      |> aggregate(
        :proper_statem.zip(state_names(history), command_names(cmds))
      )
      |> when_fail(
        IO.puts("""
        History: #{inspect(history)}
        State: #{inspect(state)}
        Result: #{inspect(result)}"
        """
        )
      )
    end
  end

  def initial_state(), do: :unregistered
  def initial_state_data() do
    %{limit: 3, errors: 0, timeouts: 0}
  end

  def unregistered(_data) do
    [{:ok, {:call, BreakShim, :success, []}}]
  end

  def ok(_data) do
    [
      {:history, {:call, BreakShim, :success, []}},
      {:history, {:call, BreakShim, :err, [valid_error()]}},
      {:tripped, {:call, BreakShim, :err, [valid_error()]}},
      {:history, {:call, BreakShim, :ignored_error, [ignored_error()]}},
      {:history, {:call, BreakShim, :timeout, []}},
      {:tripped, {:call, BreakShim, :timeout, []}},
      {:blocked, {:call, BreakShim, :manual_block, []}},
      {:ok, {:call, BreakShim, :manual_deblock, []}},
      {:ok, {:call, BreakShim, :manual_reset, []}}
    ]
  end

  def tripped(_data) do
    [
      {:history, {:call, BreakShim, :success, []}},
      {:history, {:call, BreakShim, :err, [valid_error()]}},
      {:history, {:call, BreakShim, :ignored_error, [ignored_error()]}},
      {:history, {:call, BreakShim, :timeout, []}},
      {:ok, {:call, BreakShim, :manual_deblock, []}},
      {:ok, {:call, BreakShim, :manual_reset, []}},
      {:blocked, {:call, BreakShim, :manual_block, []}}
    ]
  end

  def blocked(_data) do
    [
      {:history, {:call, BreakShim, :success, []}},
      {:history, {:call, BreakShim, :err, [valid_error()]}},
      {:history, {:call, BreakShim, :ignored_error, [ignored_error()]}},
      {:history, {:call, BreakShim, :timeout, []}},
      {:history, {:call, BreakShim, :manual_deblock, []}},
      {:history, {:call, BreakShim, :manual_reset, []}},
      {:ok, {:call, BreakShim, :manual_block, []}}
    ]
  end

  def valid_error() do
    elements([:badarg, :badmatch, :badarith, :whatever])
  end

  def ignored_error() do
    elements([:ignore1, :ignore2])
  end

  def precondition(:unregistered, :ok, _, {:call, _, call, _}) do
    call == :success
  end
  def precondition(:ok, to, %{errors: n, limit: l}, {:call, _, :err, _}) do
    (to == :tripped and n + 1 == l) or (to == :ok and n + 1 != l)
  end
  def precondition(:ok, to, %{timeouts: n, limit: l}, {:call, _, :timeout, _}) do
    (to == :tripped and n + 1 == l) or (to == :ok and n + 1 != l)
  end
  def precondition(
    :ok,
    to,
    %{timeouts: n, limit: l},
    {:call, _, :timeout, _}
  ) do
    (to == :tripped and n + 1 == l) or (to == :ok and n + 1 != l)
  end
  def precondition(_from, _to, _data, _call) do
    true
  end

  def next_state_data(:ok, _, data = %{errors: n}, _, {_, _, :err, _}) do
    %{data | errors: n + 1}
  end
  def next_state_data(:ok, _, data = %{timeouts: n}, _, {_, _, :timeout, _}) do
    %{data | timeouts: n + 1}
  end
  def next_state_data(_from, _to, data, _, {_, _, :manual_deblock, _}) do
    %{data | errors: 0, timeouts: 0}
  end
  def next_state_data(_from, _to, data, _, {_, _, :manual_reset, _}) do
    %{data | errors: 0, timeouts: 0}
  end
  def next_state_data(_from, _to, data, _res, {:call, _m, _f, _args}) do
    data
  end

  def postcondition(:tripped, :tripped, _data, _call, {:error, {:circuit_breaker, _}}) do
    true
  end
  def postcondition(_, :blocked, _data, {_, _, :manual_block, _}, :ok) do
    true
  end
  def postcondition(_from, :blocked, _data, _call, {:error, {:circuit_breaker, _}}) do
    true
  end
  def postcondition(_, :ok, _data, {_, _, :success, _}, :success) do
    true
  end
  def postcondition(_, :ok, _data, {_, _, :manual_deblock, _}, :ok) do
    true
  end
  def postcondition(_, _, _data, {_, _, :manual_reset, _}, :ok) do
    true
  end
  def postcondition(:ok, _to, _data, {_, _, :timeout, _}, {:error, :timeout}) do
    true
  end
  def postcondition(:ok, _to, _data, {_, _, :err, _}, {:error, err}) do
    not Enum.member?([:ignore1, :ignore2], err)
  end
  def postcondition(:ok, _to, _data, {_, _, :ignored_error, _}, {:error, err}) do
    Enum.member?([:ignore1, :ignore2], err)
  end
  def postcondition(_from, _to, _data, {:call, _m, _f, _args}, _res) do
    false
  end
end
