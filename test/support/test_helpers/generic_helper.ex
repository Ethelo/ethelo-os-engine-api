defmodule EtheloApi.TestHelper.GenericHelper do
  @moduledoc """
  Generic helpers used in model tests
  """

  import ExUnit.Assertions

  def error_diff(expected, actual) do
    {expected -- actual, actual -- expected}
  end

  def assert_with_message(expected, result, message) do
    options = [left: expected, right: result, message: message]
    assert(expected == result, options)
  end

  def assert_with_function(expected, result, function, options \\ []) do
    options = options |> Keyword.put(:left, expected) |> Keyword.put(:right, result)
    assert(function.(expected) == function.(result), options)
  end

  def assert_decimal_eq(expected, actual) when is_float(expected) do
    assert Decimal.compare(Decimal.from_float(expected), actual) == :eq
  end

  def assert_decimal_eq(%Decimal{} = expected, actual) do
    assert Decimal.compare(expected, actual) == :eq
  end

  def assert_equivalent_slug(expected, result) do
    assert quick_slugger(expected) == result
  end

  @spec assert_id_in_result(integer(), [map()]) :: any()
  def assert_id_in_result(expected_id, result) do
    ids = extract_ids(result)
    present = to_string(expected_id) in ids
    assert present
  end

  @spec refute_id_in_result(integer(), [map()]) :: any()
  def refute_id_in_result(expected_id, result) do
    ids = extract_ids(result)
    present = to_string(expected_id) in ids
    refute present
  end

  @spec assert_id_lists_match([integer | String.t()], [integer | String.t()]) :: any()
  def assert_id_lists_match(expected, result) do
    expected = stringify_and_sort(expected)
    result = stringify_and_sort(result)
    assert expected == result
  end

  @spec assert_result_ids_match([map()], [map()]) :: any()
  def assert_result_ids_match(expected, result) do
    expected = extract_ids(expected)
    result = extract_ids(result)
    assert expected == result
  end

  @spec assert_odvs_in_result(list(map()), list(map())) :: list
  def assert_odvs_in_result(odvs, result) do
    odvs = convert_odvs_to_tuples(odvs)
    result = convert_odvs_to_tuples(result)

    for odv <- odvs do
      assert odv in result
    end
  end

  def offset_date_value(offset) do
    DateTime.utc_now() |> DateTime.add(offset) |> DateTime.truncate(:second)
  end

  def to_graphql_enum(value) when is_atom(value), do: to_graphql_enum(Atom.to_string(value))

  def to_graphql_enum(value) do
    String.upcase(value)
  end

  def to_graphql_input_params(attrs, decision) do
    attrs = Map.put(attrs, :decision, decision)
    %{input: attrs}
  end

  def decimal_attr_to_float(attrs, attr_name) do
    updated = attrs |> Map.get(attr_name) |> decimal_to_float()
    Map.put(attrs, attr_name, updated)
  end

  def decimal_to_float(%Decimal{} = value) do
    Decimal.to_float(value)
  end

  def decimal_to_float(value), do: value

  defp quick_slugger(string) do
    ~r/[^a-z0-9]+/i
    |> Regex.replace(string, "-")
    |> String.downcase()
  end

  # convert to string so it doesn't show in exunit as a charlist
  @spec extract_ids([map()]) :: [String.t()]
  def extract_ids(list) when is_list(list) do
    list
    |> Enum.map(fn item ->
      Map.get(item, :id) || Map.get(item, "id")
    end)
    |> Enum.map(&to_string/1)
    |> Enum.sort()
  end

  def stringify_and_sort(list) when is_list(list) do
    list
    |> Enum.map(&to_string/1)
    |> Enum.sort()
  end

  def convert_odvs_to_tuples(list), do: Enum.map(list, &convert_odv_to_tuple/1)

  @spec convert_odv_to_tuple(map()) :: any()
  def convert_odv_to_tuple(%{} = odv) do
    option_id = id_if_present(odv, :option)
    option_detail_id = id_if_present(odv, :option_detail)
    {option_id, option_detail_id, Map.get(odv, :value)}
  end

  @spec id_if_present(map, atom()) :: any
  def id_if_present(map, key) do
    id_key = String.to_atom("#{key}_id")
    value = Map.get(map, key)

    cond do
      Map.has_key?(map, id_key) -> Map.get(map, id_key)
      is_map(value) -> Map.get(value, :id)
      true -> nil
    end
  end

  def add_calculation_id(attrs, %{calculation: calculation}),
    do: Map.put(attrs, :calculation_id, calculation.id)

  def add_calculation_id(attrs, _deps), do: attrs

  def add_criteria_id(attrs, %{criteria: criteria}), do: Map.put(attrs, :criteria_id, criteria.id)
  def add_criteria_id(attrs, _deps), do: attrs

  def add_decision_id(attrs, %{decision: decision}), do: Map.put(attrs, :decision_id, decision.id)
  def add_decision_id(attrs, _deps), do: attrs

  def add_option_id(attrs, %{option: option}), do: Map.put(attrs, :option_id, option.id)
  def add_option_id(attrs, _deps), do: attrs

  def add_option_category_id(attrs, %{option_category: option_category}),
    do: Map.put(attrs, :option_category_id, option_category.id)

  def add_option_category_id(attrs, _deps), do: attrs

  def add_option_detail_id(attrs, %{option_detail: option_detail}),
    do: Map.put(attrs, :option_detail_id, option_detail.id)

  def add_option_detail_id(attrs, _deps), do: attrs

  def add_option_filter_id(attrs, %{option_filter: option_filter}),
    do: Map.put(attrs, :option_filter_id, option_filter.id)

  def add_option_filter_id(attrs, _deps), do: attrs

  def add_participant_id(attrs, %{participant: participant}),
    do: Map.put(attrs, :participant_id, participant.id)

  def add_participant_id(attrs, _deps), do: attrs

  def add_scenario_config_id(attrs, %{scenario_config: scenario_config}),
    do: Map.put(attrs, :scenario_config_id, scenario_config.id)

  def add_scenario_config_id(attrs, _deps), do: attrs

  def add_scenario_set_id(attrs, %{scenario_set: scenario_set}),
    do: Map.put(attrs, :scenario_set_id, scenario_set.id)

  def add_scenario_set_id(attrs, _deps), do: attrs

  def add_scenario_id(attrs, %{scenario: scenario}), do: Map.put(attrs, :scenario_id, scenario.id)
  def add_scenario_id(attrs, _deps), do: attrs

  def add_variable_id(attrs, %{variable: variable}), do: Map.put(attrs, :variable_id, variable.id)
  def add_variable_id(attrs, _deps), do: attrs
end
