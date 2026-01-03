defmodule Bookstore.Sup do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    Bookstore.DB.load_queries()
    Supervisor.init([], strategy: :one_for_one)
  end
end
