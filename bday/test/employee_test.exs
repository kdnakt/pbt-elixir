

defmodule EmployeeTest do
  use ExUnit.Case
  use PropCheck
  
  property "fixed leading space" do
    forall map <- raw_employee_map() do
      emp = Employee.adapt_csv_result_shim(map)
      strs = Enum.filter(Map.keys(emp) ++ Map.values(emp), &is_binary/1)
      Enum.all?(strs, fn s -> String.first(s) != " " end)
    end
  end

end
