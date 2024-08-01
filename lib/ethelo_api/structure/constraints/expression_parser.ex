defmodule EtheloApi.Structure.ExpressionParser do
  @moduledoc """
  Given a string expression, extracts all components
  """
  @end_message "incomplete expression or methods"

  @part_types %{
    close: %{
      message: "braces must be matched and must contain expressions",
      invalid_next: [:open, :invalid, :number]
    },
    open: %{
      message: "braces must be matched and must contain expressions",
      invalid_next: [:close, :invalid, :operator, :end]
    },
    method_open: %{
      message: "methods must have open and closing methods",
      invalid_next: [:invalid, :operator, :method_close, :close, :end]
    },
    method_close: %{
      message: "methods must have open and closing methods",
      invalid_next: [:invalid, :method_open, :open, :number, :variable]
    },
    operator: %{
      message: "must have a number or Variable on each side of an operator",
      invalid_next: [:close, :invalid, :operator, :end]
    },
    number: %{
      message: "must follow a number or Variable with an operator",
      invalid_next: [:number, :invalid, :variable, :open]
    },
    variable: %{
      message: "must have a number or Variable with an operator",
      invalid_next: [:number, :invalid, :variable, :open]
    },
    invalid: %{message: "invalid syntax", invalid_next: [:invalid]},
    end: %{message: @end_message, invalid_next: [:invalid]}
  }

  defp base_map(expression) do
    %{
      expression: expression,
      invalid_next: [:close, :operator, :invalid, :end],
      error: nil,
      last_parsed: "",
      parsed: "",
      variables: [],
      methods: []
    }
  end

  def parse(nil), do: parse("")

  def parse(expression) when is_binary(expression) do
    parts = part_list(expression)

    parts
    |> Enum.reduce(base_map(expression), &validate_part/2)
    |> remove_end_error()
    |> validate_operand_present(parts)
    |> validate_braces(parts)
    |> validate_method_braces(parts)
    |> validate_operators(parts)
    |> unique_methods()
    |> validate_methods
    |> unique_variables()
    |> Map.take([:error, :last_parsed, :parsed, :variables, :methods])
  end

  defp unique_variables(map) do
    variables = map.variables |> Enum.uniq() |> Enum.sort()
    %{map | variables: variables}
  end

  defp unique_methods(map) do
    methods = map.methods |> Enum.uniq() |> Enum.sort()
    %{map | methods: methods}
  end

  defp validate_methods(%{error: error} = map) when is_binary(error), do: map
  defp validate_methods(%{methods: []} = map), do: map

  defp validate_methods(%{methods: methods} = map) do
    if Enum.any?(methods, fn name -> name != "abs" end) do
      %{map | error: "method not allowed - #{Enum.join(methods, ",")}"}
    else
      map
    end
  end

  defp remove_end_error(%{error: @end_message} = map), do: %{map | error: nil}
  defp remove_end_error(map), do: map

  defp validate_operand_present(%{error: error} = map, _) when is_binary(error), do: map

  defp validate_operand_present(%{variables: [], methods: []} = map, parts) do
    if Enum.any?(parts, fn {type, _} -> type == :number end) do
      map
    else
      %{map | error: "must contain a number, method or Variable"}
    end
  end

  defp validate_operand_present(map, _), do: map

  defp validate_braces(%{error: error} = map, _) when is_binary(error), do: map

  defp validate_braces(map, parts) do
    case open_brace_error(parts) do
      {:error, message} -> %{map | error: message}
      _ -> map
    end
  end

  defp open_brace_error(parts) do
    count = Enum.reduce_while(parts, 0, &open_brace_counter/2)

    cond do
      count == :error -> {:error, @part_types.close.message}
      count > 0 -> {:error, @part_types.close.message}
      true -> :ok
    end
  end

  defp open_brace_counter({type, _}, count) do
    cond do
      type == :open -> {:cont, count + 1}
      type == :close && count > 0 -> {:cont, count - 1}
      type == :close -> {:halt, :error}
      true -> {:cont, count}
    end
  end

  defp validate_method_braces(%{error: error} = map, _) when is_binary(error), do: map

  # add validation for method whitelist - abs
  defp validate_method_braces(map, parts) do
    case open_method_error(parts) do
      {:error, message} -> %{map | error: message}
      _ -> map
    end
  end

  defp open_method_error(parts) do
    count = Enum.reduce_while(parts, 0, &open_method_counter/2)

    cond do
      count == :error -> {:error, @part_types.method_close.message}
      count > 0 -> {:error, @part_types.method_close.message}
      true -> :ok
    end
  end

  defp open_method_counter({type, _}, count) do
    cond do
      type == :method_open -> {:cont, count + 1}
      type == :method_close && count > 0 -> {:cont, count - 1}
      type == :method_close -> {:halt, :error}
      true -> {:cont, count}
    end
  end

  defp validate_operators(%{error: error} = map, _) when is_binary(error), do: map

  defp validate_operators(map, parts) do
    case open_operator_error(parts) do
      {:error, message} -> %{map | error: message}
      _ -> map
    end
  end

  defp open_operator_error(parts) do
    count = Enum.reduce_while(parts, 0, &open_operator_counter/2)

    cond do
      count == :error -> {:error, @part_types.operator.message}
      count > 0 -> {:error, @part_types.operator.message}
      true -> :ok
    end
  end

  defp open_operator_counter({type, _}, count) do
    cond do
      type == :operator -> {:cont, count + 1}
      type in [:number, :variable] && count > 0 -> {:cont, count - 1}
      type == [:number, :variable] -> {:halt, :error}
      true -> {:cont, count}
    end
  end

  defp validate_part(_, %{error: error} = map) when is_binary(error), do: map
  defp validate_part({:space, ""}, map), do: map
  defp validate_part({:space, _} = part_tuple, map), do: add_part(map, part_tuple)

  defp validate_part({type, _} = part_tuple, %{invalid_next: invalid_next} = map) do
    if type in invalid_next do
      %{map | error: @part_types[type][:message]} |> add_part(part_tuple)
    else
      %{map | invalid_next: @part_types[type][:invalid_next]} |> add_part(part_tuple)
    end
  end

  defp add_part(map, {:variable, part}) do
    %{map | variables: [part | map.variables]} |> update_parsed(part)
  end

  defp add_part(map, {:method_open, part}) do
    %{map | methods: [String.trim(part, "{") | map.methods]} |> update_parsed(part)
  end

  defp add_part(map, {_, part}), do: update_parsed(map, part)

  defp update_parsed(map, part) do
    parsed = map.parsed <> " " <> String.trim(part)
    %{map | last_parsed: part, parsed: String.trim(parsed)}
  end

  defp part_list(expression) do
    expression
    |> correct_negative_numbers()
    |> split_expression
    |> Enum.map(&identify_part/1)
    |> Kernel.++([{:end, ""}])
  end

  # 1-1 is technically correct, but wont be matched so convert to 1 - 1
  defp correct_negative_numbers(expression) do
    expression
    |> String.replace(~r/([^\s])(\-\d)/, "\\1 \\2")
    |> String.replace(~r/([^\s])\-/, "\\1 -")
    |> String.replace(~r/\-([^\d\s])/, "- \\1")
  end

  defp identify_part(""), do: {:space, ""}
  defp identify_part("(" = part), do: {:open, part}
  defp identify_part(")" = part), do: {:close, part}
  defp identify_part("+" = part), do: {:operator, part}
  defp identify_part("-" = part), do: {:operator, part}
  defp identify_part("*" = part), do: {:operator, part}
  defp identify_part("/" = part), do: {:operator, part}
  defp identify_part("}" = part), do: {:method_close, part}

  defp identify_part(part) do
    cond do
      Regex.match?(~r/^[a-z][a-z_0-9]*\{$/i, part) -> {:method_open, part}
      Regex.match?(~r/^[a-z][a-z_0-9]*$/i, part) -> {:variable, part}
      Regex.match?(~r/^-?[0-9]+(\.[0-9]+)?$/, part) -> {:number, part}
      Regex.match?(~r/^\s+$/, part) -> {:space, part}
      true -> {:invalid, part}
    end
  end

  defp split_expression(expression) do
    Regex.split(~r/([\+\/\*\s\(\)\}]|[a-z0-9\.\-_]+{?)/i, expression,
      include_captures: true,
      trim: true
    )
  end
end
