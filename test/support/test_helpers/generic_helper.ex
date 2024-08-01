defmodule EtheloApi.Structure.TestHelper.GenericHelper do
  @moduledoc false

  import ExUnit.Assertions

  def extract_ids(list) do
    list |> Enum.map(&Map.get(&1, :id)) |> Enum.sort()
  end

  def id_if_present(map, key) do
    id_key = String.to_atom("#{key}_id")
    value = Map.get(map, key)
    cond do
      Map.has_key?(map, id_key) -> Map.get(map, id_key)
      is_map(value) ->   Map.get(value, :id)
      true -> nil
    end
  end

  defp quick_slugger(string) do
    ~r/[^a-z0-9]+/i
    |> Regex.replace(string, "-")
    |> String.downcase
  end

  def assert_equivalent_slug(expected, result) do
    assert quick_slugger(expected) == result
  end

  def assert_result_ids_match(expected, result) do
    expected = extract_ids(expected)
    result = extract_ids(result)
    assert expected == result
  end

  def refute_id_in_result(expected_id, result) do
    result = extract_ids(result)
    refute expected_id in result
  end

  def assert_odvs_in_result(odvs, result) do
    odvs = convert_odvs_to_tuples(odvs)
    result = convert_odvs_to_tuples(result)

    for odv <- odvs do
      assert odv in result
    end
  end

  def convert_odvs_to_tuples(list), do: Enum.map(list, &convert_odv_to_tuple/1)
  def convert_odv_to_tuple(odv) do
    option_id = id_if_present(odv, :option)
    option_detail_id = id_if_present(odv, :option_detail)
    {option_id, option_detail_id, Map.get(odv, :value)}
  end

  def to_enum_value(value) when is_atom(value), do: to_enum_value(Atom.to_string(value))
  def to_enum_value(value) do
     String.upcase(value)
   end
end
