defmodule EtheloApi.Constraints.ValueParser do

  def to_matchable_string(value, format) do
    case format do
      :boolean -> boolean_value(value)
      :integer -> integer_value(value)
      :float -> float_value(value)
      :string -> to_string(value)
    end
    |> case do
      :error -> {:error, value}
      valid -> {:ok, valid}
    end
  end

  def integer_value(nil), do: "0"
  def integer_value(""), do: "0"
  def integer_value(value) do
    case Float.parse(value) do
      {number, _} -> number |> round() |> to_string()
      :error -> :error
    end
  end

  def float_value(nil), do: "0"
  def float_value(""), do: "0"
  def float_value(value) when is_integer(value) do
    value |> to_string()
  end
  def float_value(value) do
    value = Regex.replace(~r/^\./, value, "0.")

    case Float.parse(value) do
      {number, _} -> number |> to_string()
      :error -> :error
    end
  end

  def boolean_value(1), do: "true"
  def boolean_value(true), do: "true"
  def boolean_value("true"), do: "true"
  def boolean_value(_), do: "false"

end
