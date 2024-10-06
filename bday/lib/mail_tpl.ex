defmodule Bday.MailTpl do

  def body(emp) do
    name = Bday.Employee.first_name(emp)
    "Happy birthday, dear #{name}!"
  end

  def full(emp) do
    {[Bday.Employee.email(emp)], "Happy birthday!", body(emp)}
  end
end
