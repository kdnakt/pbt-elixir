defmodule Bookstore.Init do
  def main(_args) do
    File.mkdir_p!("postgres/data")
    stdout = IO.stream(:stdio, :line)

    IO.puts("initializing database structure...")
    System.cmd("initdb", ["-D", "postgres/data"], into: stdout)
    IO.puts("starting postgres...")

    args = ["-D", "postgres/data", "-l", "logfile", "start"]
    case :os.type() do
      {:win32, _} ->
        spawn(fn -> System.cmd("pg_ctl", args, into: stdout) end)
      {:unix, _} ->
        System.cmd("pg_ctl", args, into: stdout)
    end
    Process.sleep(5000)
    IO.puts("setting up 'bookstore_db' database...")
    System.cmd("psql", ["-h", "localhost", "-d", "template1", "-c", "CREATE DATABASE bookstore_db;"], into: stdout)
    IO.puts("OK.")
    :init.stop()
  end
end
