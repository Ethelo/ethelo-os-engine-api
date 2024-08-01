defmodule GraphqlBuilder.GraphqlFragmentBuilder do
  @moduledoc """
  Tools to generate Graphql query fragments
  """

  @doc """
  convert a map of fields to a graphql params format

  keys are camelized, and non-numeric values are surround by quotes
  """
  # @spec to_graphql_params(map()) :: String.t()
  def to_graphql_params(%{} = params) do
    params
    |> camelize_keys
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.map_join("\n", &to_graphql_param_pair/1)
  end

  def to_graphql_param_pair({k, v}) do
    v = to_graphql_value(v)
    "#{k}: #{v} "
  end

  def to_graphql_value(%Decimal{} = v), do: Decimal.to_float(v)
  def to_graphql_value(%DateTime{} = v), do: DateTime.to_iso8601(v)
  def to_graphql_value(nil), do: "null"

  def to_graphql_value(v) when is_map(v), do: to_graphql_params(v) |> add_braces()

  def to_graphql_value(v) when is_list(v) do
    combined = Enum.join(v, ",")
    "[#{combined}]"
  end

  def to_graphql_value(v) when is_boolean(v), do: "#{v}"
  def to_graphql_value(v) when is_integer(v), do: "#{v}"
  def to_graphql_value(v) when is_float(v), do: "#{v} "
  def to_graphql_value(v) when is_binary(v), do: ~s["#{v}"]

  # assume enum
  def to_graphql_value(v) when is_atom(v) do
    v |> Atom.to_string() |> String.upcase()
  end

  def to_graphql_value(v) when is_atom(v), do: ~s["#{v}"]

  @doc """
  convert a list of fields to a new line separated list of field names
  """
  # fields: [:slug, :id]}
  @spec simple_fields(list()) :: String.t()
  def simple_fields(field_list) do
    field_list
    |> build_fields()
  end

  # fields:  [:successful, %{ name: :messages, fields: [:code, :field]} ]
  def build_fields(field_definition) when is_list(field_definition) do
    field_definition
    |> Enum.sort_by(&sort_by_name/1)
    |> Enum.map_join("\n", &definition_to_graphql/1)
  end

  # :field_name
  def definition_to_graphql(definition) when is_binary(definition) or is_atom(definition) do
    to_field_name(definition)
  end

  # %{field: :options, args: %{slug: "foo"}, fields: [:slug]}
  def definition_to_graphql(%{name: name, args: args, fields: fields}) do
    field_name = to_field_name(name)
    args = to_graphql_params(args)
    subquery = build_fields(fields)

    ~s[
        #{field_name}(
          #{args}
        ){
          #{subquery}
        }
      ]
  end

  #  %{name: :count, args: %{status: "success", global: false}}
  def definition_to_graphql(%{name: name, args: args}) do
    field_name = to_field_name(name)
    args = to_graphql_params(args)

    ~s[
        #{field_name}(
          #{args}
        )
      ]
  end

  #  %{name: :solve_dump, fields: [:id, :scenario_set_id, :error]},
  def definition_to_graphql(%{name: name, fields: fields}) do
    field_name = to_field_name(name)
    subquery = build_fields(fields)

    ~s[
        #{field_name}{
          #{subquery}
        }
      ]
  end

  defp to_field_name(item) do
    item |> to_string() |> camelize()
  end

  @spec to_graphql_response(map()) :: String.t()
  def to_graphql_response(%{} = example) do
    example
    |> camelize_keys()
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.map(fn {k, v} ->
      v = to_graphql_value(v)
      ~s[ "#{k}": #{v},]
    end)
    |> Enum.join("\n")
    |> String.trim(",")
    |> add_braces()
  end

  @spec camelize_keys(map()) :: map()
  def camelize_keys(%{} = map) do
    map
    |> Enum.map(fn {k, v} -> {camelize(k), v} end)
    |> Enum.into(%{})
  end

  def camelize(v), do: Inflex.camelize(v, :lower)

  def sort_by_name(%{name: name}), do: to_string(name)
  def sort_by_name(name), do: to_string(name)

  def add_braces(content) do
    ~s[
      {
        #{content}
      }
    ]
  end

  # do not strip newlines as tehy are required in graphql queries
  def strip_starting_whitespace(str) do
    str
    |> String.replace(~r/\n[\t ]+/, "\n")
    |> String.trim()
  end
end
