  

defmodule Bday.Employee do
  
  if Mix.env() == :test do
    def adapt_csv_result_shim(map), do: adapt_csv_result(map)
  end
  
  @opaque employee() :: %{required(String.t()) => term()}
  @opaque handle() :: {:raw, [employee()]}
  
  def from_csv(string) do
    {:raw,
     for map <- Bday.Csv.decode(string) do
       adapt_csv_result(map)
     end}
  end
  
  defp adapt_csv_result(map) do
    map =
      for {k, v} <- map, into: %{} do
        {trim(k), maybe_null(trim(v))}
      end

    dob = Map.fetch!(map, "date_of_birth")
    %{map | "date_of_birth" => parse_date(dob)}
  end
  
  defp trim(str), do: String.trim_leading(str, " ")

  defp maybe_null(""), do: nil
  defp maybe_null(str), do: str

  defp parse_date(str) do
    [y, m, d] = Enum.map(String.split(str, "/"), &String.to_integer(&1))
    {:ok, date} = Date.new(y, m, d)
    date
  end
end
