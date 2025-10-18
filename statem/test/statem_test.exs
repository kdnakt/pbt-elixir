# defmodule StatemTest do
#   use ExUnit.Case
#   use PropCheck
#   use PropCheck.StateM

#   property "stateful property" do
#     forall cmds <- commands(__MODULE__) do
#       ActualSystem.start_link([])
#       {history, state, result} = run_commands(__MODULE__, cmds)
#       ActualSystem.stop()

#       (result == :ok)
#       |> aggregate(command_names(cmds))
#       |> when_fail(
#         IO.puts("""
#         History: #{inspect(history, pretty: true)}
#         State: #{inspect(state, pretty: true)}
#         Result: #{inspect(result, pretty: true)}
#         """)
#       )
#     end
#   end

#   def initial_state() do
#     %{}
#   end

#   def command(_state) do
#     oneof([
#       {:call, ActualSystem, :some_call, [term(), term()]}
#     ])
#   end

#   def precondition(_state, {:call, _mod, _fun, _args}) do
#     true
#   end

#   def postcondition(_state, {:call, _mod, _fun, _args}, _res) do
#     true
#   end

#   def next_state(state, _res, {:call, _mod, _fun, _args}) do
#     newstate = state
#     newstate
#   end
# end
