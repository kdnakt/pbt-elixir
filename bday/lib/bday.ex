defmodule Bday do
  @moduledoc """
  Documentation for `Bday`.
  """

  def run(path) do
    set =
      path
      |> File.read!()
      |> Bday.Employee.from_csv()
      |> Bday.Employee.filter_birthday(DateTime.to_date(DateTime.utc_now()))
      |> Bday.Employee.fetch()

    for emp <- set do
      emp
      |> Bday.MailTpl.full()
      |> send_email()
    end

    :ok
  end

  defp send_email({to, topic, body}) do
    IO.puts("send birthday email to #{to}")
    IO.puts("topic: #{topic}")
    IO.puts("body: #{body}")
  end

end
