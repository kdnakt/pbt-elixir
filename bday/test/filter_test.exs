defmodule FilterTest do
  use ExUnit.Case
  alias Bday.Filter, as: Filter

  test "Filtering test in property style" do
    years = generate_years_data(2018, 2038)
    people = generate_people_for_year(3)

    for yeardata <- years do
      birthdays = find_birthdays_for_year(people, yeardata)
      every_birthday_once(people, birthdays)
      on_right_date(people, birthdays)
    end
  end


  defp find_birthdays_for_year(_, []), do: []

  defp find_birthdays_for_year(people, [day | year]) do
    found = Filter.birthday(people, day)
    [{day, found} | find_birthdays_for_year(people, year)]
  end

  # generators
  defp generate_years_data(stop, stop), do: []

  defp generate_years_data(start, stop) do
    [generate_year_data(start) | generate_years_data(start + 1, stop)]
  end

  defp generate_year_data(year) do
    {:ok, date} = Date.new(year, 1, 1)

    days_in_feb =
      case Date.leap_year?(date) do
        true -> 29
        false -> 28
      end

    month(year, 1, 31) ++
      month(year, 2, days_in_feb) ++
      month(year, 3, 31) ++
      month(year, 4, 30) ++
      month(year, 5, 31) ++
      month(year, 6, 30) ++
      month(year, 7, 31) ++
      month(year, 8, 31) ++
      month(year, 9, 30) ++
      month(year, 10, 31) ++ month(year, 11, 30) ++ month(year, 12, 31)
  end

  defp month(y, m, 1) do
    {:ok, date} = Date.new(y, m, 1)
    [date]
  end

  defp month(y, m, n) do
   {:ok, date} = Date.new(y, m, n)
   [date | month(y, m, n - 1)]
  end

  defp generate_people_for_year(n) do
    year_seed = generate_year_data(2016)
    Enum.flat_map(1..n, fn _ -> people_for_year(year_seed) end)
  end

  defp people_for_year(year) do
    for date <- year do
      person_for_date(date)
    end
  end

  defp person_for_date(%Date{montj: m, day: d} = date) do
    case Date.new(:rand.uniform(100) + 1900, m, d) do
      {:error, :invalid_date} ->
        person_for_date(date)
      {:ok, date} ->
        ${"name" => make_ref(), "date_of_birth" => date}
    end
  end
end
