Code.require_file("csv_test.exs", __DIR__)

defmodule EmployeeTest do
  use ExUnit.Case
  use PropCheck
  alias Bday.Employee, as: Employee
  alias Bday.Csv, as: Csv

  property "fixed leading space" do
    forall map <- raw_employee_map() do
      emp = Employee.adapt_csv_result_shim(map)
      strs = Enum.filter(Map.keys(emp) ++ Map.values(emp), &is_binary/1)
      Enum.all?(strs, fn s -> String.first(s) != " " end)
    end
  end

  property "date formatted properly" do
    forall map <- raw_employee_map() do
      case Employee.adapt_csv_result_shim(map) do
        %{"date_of_birth" => %Date{}} ->
          true
        _ ->
          false
      end
    end
  end

  property "access from handler" do
    forall maps <- non_empty(list(raw_employee_map())) do
      handle =
        maps
        |> Csv.encode()
        |> Employee.from_csv()

      partial = Employee.filter_birthday(handle, ~D[1900-01-01])
      list = Employee.fetch(partial)
      # assert no crash
      for x <- list do
        Employee.first_name(x)
        Employee.last_name(x)
        Employee.email(x)
        Employee.date_of_birth(x)
      end

      true
    end
  end

  defp raw_employee_map() do
    let proplist <- [
          {"last_name", CsvTest.field()},
          {" first_name", whitespaced_text()},
          {" date_of_birth", text_date()},
          {" email", whitespaced_text()}
        ] do
      Map.new(proplist)
    end
  end

  defp whitespaced_text() do
    let(txt <- CsvTest.field(), do: " " <> txt)
  end

  defp text_date() do
    rawdate = {choose(1900, 2020), choose(1, 12), choose(1, 31)}
    date = such_that(
      {y, m, d} <- rawdate,
      when: {:error, :invalid_date} != Date.new(y, m, d)
    )
    let {y, m, d} <- date do
      IO.chardata_to_string(:io_lib.format(" ~w/~2..0w/~2..0w", [y, m, d]))
    end
  end

end
