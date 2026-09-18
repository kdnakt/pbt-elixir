defmodule FSMTest do
  use ExUnit.Case
  use PropCheck
  use PropCheck.FSM

  property "FSM property", [:verbose] do
    forall cmds <- commands(__MODULE__) do
      ActualSystem.start_link()
      {history, state, result} = run_commands(__MODULE__, cmds)
      ActualSystem.stop()

      (result == :ok)
      |> aggregate(
        :proper_statem.zip(state_names(history), command_names(cmds))
      )
      |> when_fail(
        IO.puts("""
        History: #{inspect(history)}
        State: #{inspect(state)}
        Result: #{inspect(result)}
        """)
      )
    end
  end

  def initial_state(), do: :on
  def initial_state_data(), do: %{}

  def on(_data) do
    [{:off, {:call, ActualSystem, :some_call, [term(), term()]}}]
  end

  def off(_data) do
    [
      {:off, {:call, ActualSystem, :some_call, [term(), term()]}},
      {:history, {:call, ActualSystem, :some_call, [term(), term()]}},
      {{:service, :sub, :state},
       {:call, ActualSystem, :some_call, [term(), term()]}}
    ]
  end

  def service(_sub, _state, _data) do
    [{:on, {:call, ActualSystem, :some_call, [term(), term()]}}]
  end

  def weight(_from_state, _to_state, _data) do
    1
  end
end
