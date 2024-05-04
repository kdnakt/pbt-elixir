

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

