defmodule EtheloApi.Structure.OptionDetailValueTest do
  @moduledoc """
  Validations and basic access for OptionDetailValue
  Includes both the context EtheloApi.Structure, and specific functionality on the Option schema
  """
  use EtheloApi.DataCase
  import EtheloApi.Structure.Factory
  @moduletag option_detail_value: true, ethelo: true, ecto: true

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.OptionDetailValue
  alias EtheloApi.Structure.Option
  alias EtheloApi.Structure.OptionDetail

  def valid_attrs(%{option: option, option_detail: option_detail}) do
    %{
    value: "foo", option_id: option.id, option_detail_id: option_detail.id,
    }
  end

  def invalid_attrs() do
    %{option_id: 123, option_detail_id: 123, value: nil}
  end

  def assert_equivalent(expected, result) do
    assert expected.option_id == result.option_id
    assert expected.option_detail_id == result.option_detail_id
    assert to_string(expected.value) == result.value
  end

  describe "list_option_detail_values/3" do

    test "returns records matching a Decision" do
      create_option_detail_value() # should not be returned
      %{option_detail_value: first, decision: decision} = create_option_detail_value()
      %{option_detail_value: second} = create_option_detail_value(decision)

      result = Structure.list_option_detail_values(decision)
      assert [%OptionDetailValue{}, %OptionDetailValue{}] = result
      assert_odvs_in_result([first, second], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Structure.list_option_detail_values(nil) end
    end

    test "returns selected fields" do
      %{option_detail: option_detail, decision: decision} = create_option_detail()
      %{option_detail_value: odv} = create_option_detail_value(decision, option_detail)

      result = Structure.list_option_detail_values(decision, %{}, [:value, :option_detail_id])

      assert [first_result] = result
      refute %OptionDetailValue{} == first_result
      assert %{option_detail_id: odv.option_detail_id, value: odv.value} == first_result
    end

    test "returns distinct records" do

      decision = create_decision();

      create_option_detail_value(decision, :integer, 10)
      create_option_detail_value(decision, :integer, 4)
      create_option_detail_value(decision, :integer, 10)

      result = Structure.list_option_detail_values(decision, %{distinct: true}, [:value])

      assert [_, _] = result
      assert %{value: "10"} in result
      assert %{value: "4"} in result
    end
  end

  describe "get_option_detail_value/3" do
    test "loads by objects" do
      %{option: option, decision: decision, option_detail: option_detail} = create_option_detail_value()

      result = Structure.get_option_detail_value(option, option_detail, decision.id)

      assert %OptionDetailValue{} = result
      assert result.option_id == option.id
      assert result.option_detail_id == option_detail.id
    end

    test "loads by attrs" do
      %{option: option, decision: decision, option_detail: option_detail} = create_option_detail_value()

      attrs = %{option_id: option.id, option_detail_id: option_detail.id}
      result = Structure.get_option_detail_value(attrs, decision.id)

      assert %OptionDetailValue{} = result
      assert result.option_id == option.id
      assert result.option_detail_id == option_detail.id
    end

    test "returns errors when Decision does not match" do
      %{option: option, option_detail: option_detail} = create_option_detail_value()
      decision2 = create_decision()

      result = Structure.get_option_detail_value(option, option_detail, decision2)
      assert nil == result
    end

    test "raises without a Decision" do
      %{option: option, option_detail: option_detail} = create_option_detail_value()

      assert_raise ArgumentError, ~r/Decision/, fn ->
        Structure.get_option_detail_value(option, option_detail, nil)
      end
    end

    test "raises without an Option" do
      %{decision: decision, option_detail: option_detail} = create_option_detail_value()

      assert_raise ArgumentError, ~r/Option/, fn ->
        Structure.get_option_detail_value(nil, option_detail, decision)
      end
    end

    test "raises without an OptionDetail" do
      %{decision: decision, option: option} = create_option_detail_value()

      assert_raise ArgumentError, ~r/OptionDetail/, fn ->
        Structure.get_option_detail_value(option, nil, decision)
      end
    end
  end

  describe "upsert_option_detail_value/3" do
    test "creates" do
      deps = option_detail_value_deps()
      %{decision: decision} = deps

      attrs = valid_attrs(deps)
      result = Structure.upsert_option_detail_value(decision, attrs)

      assert {:ok, %OptionDetailValue{} = odv} = result
      assert_equivalent(attrs, odv)
    end

    test "updates on existing value" do
      deps = create_option_detail_value()
      %{decision: decision} = deps

      attrs = deps |> valid_attrs() |> Map.put(:value, "foobar")
      result = Structure.upsert_option_detail_value(decision, attrs)

      assert {:ok, %OptionDetailValue{} = odv} = result
      assert_equivalent(attrs, odv)
    end
  end

  describe "deletes_option_detail_value/1" do
    test "delete" do
      %{option_detail_value: existing, decision: decision} = create_option_detail_value()

      result = Structure.delete_option_detail_value(existing, decision)

      assert {:ok, %OptionDetailValue{} = odv} = result
      assert nil == Repo.get_by(OptionDetailValue, option_detail_id: odv.option_detail_id, option_id: odv.option_id)
      assert nil !== Repo.get(Decision, decision.id)
      assert nil !== Repo.get(Option, odv.option_id)
      assert nil !== Repo.get(OptionDetail, odv.option_detail_id)
    end
  end

  describe "documentation" do
    test "OptionDetailValue has documentation module" do
      assert %{} = OptionDetailValue.strings()
      assert %{} = OptionDetailValue.examples()
      assert is_list(OptionDetailValue.fields())
    end
  end

end
