defmodule EtheloApi.Structure.OptionDetailValueTest do
  @moduledoc """
   Validations and basic access for OptionDetailValue
   Includes both the context EtheloApi.Structure, and specific functionality on the Option schema

  """
  use EtheloApi.DataCase
  @moduletag option_detail_value: true, ecto: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.OptionDetailValueHelper

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.OptionDetailValue
  alias EtheloApi.Structure.Option
  alias EtheloApi.Structure.OptionDetail

  describe "list_option_detail_values/3" do
    test "filters by decision_id" do
      _excluded = create_option_detail_value()
      %{option_detail_value: to_match1, decision: decision} = create_option_detail_value()
      %{option_detail_value: to_match2} = create_option_detail_value(decision)

      result = Structure.list_option_detail_values(decision)
      assert [%OptionDetailValue{}, %OptionDetailValue{}] = result
      assert_odvs_in_result([to_match1, to_match2], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Structure.list_option_detail_values(nil) end
    end

    test "returns selected fields" do
      %{option_detail: option_detail, decision: decision} = create_option_detail()
      %{option_detail_value: odv} = create_option_detail_value(decision, option_detail)

      result = Structure.list_option_detail_values(decision, %{}, [:value, :option_detail_id])

      assert [first_result] = result
      refute %OptionDetailValue{} == first_result
      assert %{option_detail_id: odv.option_detail_id, value: odv.value} == first_result
    end

    test "filters distinct records" do
      decision = create_decision()

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
    test "filters by structs" do
      %{option: option, decision: decision, option_detail: option_detail} =
        create_option_detail_value()

      result = Structure.get_option_detail_value(option, option_detail, decision.id)

      assert %OptionDetailValue{} = result
      assert result.option_id == option.id
      assert result.option_detail_id == option_detail.id
    end

    test "filters by ids" do
      %{option: option, decision: decision, option_detail: option_detail} =
        create_option_detail_value()

      attrs = %{option_id: option.id, option_detail_id: option_detail.id}
      result = Structure.get_option_detail_value(attrs, decision.id)

      assert %OptionDetailValue{} = result
      assert result.option_id == option.id
      assert result.option_detail_id == option_detail.id
    end

    test "Decision mismatch returns changeset" do
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
    test "creates with valid data" do
      deps = option_detail_value_deps()
      %{decision: decision} = deps

      attrs = valid_attrs(deps)
      result = Structure.upsert_option_detail_value(attrs, decision)

      assert {:ok, %OptionDetailValue{} = odv} = result
      assert_equivalent(attrs, odv)
    end

    test "updates on existing value" do
      deps = create_option_detail_value()
      %{decision: decision} = deps

      attrs = deps |> valid_attrs() |> Map.put(:value, "foobar")
      result = Structure.upsert_option_detail_value(attrs, decision)

      assert {:ok, %OptionDetailValue{} = odv} = result
      assert_equivalent(attrs, odv)
    end
  end

  describe "deletes_option_detail_value/1" do
    test "delete" do
      %{option_detail_value: to_delete, decision: decision} = create_option_detail_value()

      result = Structure.delete_option_detail_value(to_delete, decision)

      assert {:ok, %OptionDetailValue{} = odv} = result

      existing =
        Repo.get_by(OptionDetailValue,
          option_detail_id: odv.option_detail_id,
          option_id: odv.option_id
        )

      assert nil == existing

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
