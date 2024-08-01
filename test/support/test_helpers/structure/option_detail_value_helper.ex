defmodule EtheloApi.Structure.TestHelper.OptionDetailValueHelper do
  @moduledoc """
  OptionDetailValue specific test tools
  """
  import EtheloApi.TestHelper.GenericHelper
  import ExUnit.Assertions

  def fields() do
    %{
      inserted_at: :date,
      option_detail_id: :string,
      option_id: :string,
      updated_at: :date,
      value: :string
    }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  def input_field_names() do
    [
      :option_id,
      :option_detail_id,
      :value
    ]
  end

  def empty_attrs() do
    %{
      option_id: nil,
      option_detail_id: nil,
      value: nil
    }
  end

  def invalid_attrs() do
    %{option_id: 123, option_detail_id: 123, value: nil}
  end

  def valid_attrs(%{} = deps) do
    %{
      value: "foo"
    }
    |> add_option_id(deps)
    |> add_option_detail_id(deps)
  end

  def assert_equivalent(expected, result) do
    assert expected.option_id == result.option_id
    assert expected.option_detail_id == result.option_detail_id
    assert to_string(expected.value) == result.value
  end
end
