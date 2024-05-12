defmodule CsvTest do
  use ExUnit.Case
  use PropCheck

  property "encode and decode csv" do
    forall maps <- csv_source() do
      maps == Csv.decode(Csv.encode(maps))
    end
  end

  def csv_source() do
    let size <- pos_integer() do
      let keys <- header(size) do
        list(entry(size, keys))
      end
    end
  end

  def entry(size, keys) do
    let vals <- record(size) do
      Map.new(Enum.zip(keys, vals))
    end
  end

  def header(size) do
    vector(size, name())
  end

  def record(size) do
    vector(size, field())
  end

  def name() do
    field()
  end

  def field() do
    oneof([unquoted_text(), quotable_text()])
  end

  def unquoated_text() do
    let chars <- list(elements(textdata())) do
      to_string(chars)
    end
  end

  def quotable_text() do
    let chars <- list(elements('\r\n",' ++ textdata())) do
      to_string(chars)
    end
  end

  def textdata() do
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789' ++
     ':;<=>?@ !#$%&\'()*+-./[\\]fi_`{|}~'
  end
end  
