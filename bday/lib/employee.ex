  

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
    for {k, v} <- map, into: %{} do
      {trim(k), trim(v)}
    end
  end
  
  defp trim(str), do: String.trim_leading(str, " ")

end