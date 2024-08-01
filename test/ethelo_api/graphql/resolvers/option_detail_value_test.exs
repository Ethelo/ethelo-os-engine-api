defmodule EtheloApi.Graphql.Resolvers.OptionDetailValueTest do
  @moduledoc """
  Validations and basic access for OptionDetailValue resolver
  through graphql.
  Note: Functionality is provided through the OptionDetailValueResolver context, so these tests
  will cover a limited amount of cases. For details about edge cases or
  specifics of error messages, please refer to `EtheloApi.Structure.OptionDetailValueTest`

  """
  use EtheloApi.DataCase
  @moduletag option_detail_value: true, graphql: true

  import EtheloApi.Structure.Factory

  alias EtheloApi.Structure
  alias EtheloApi.Structure.OptionDetailValue
  alias EtheloApi.Graphql.Resolvers.OptionDetailValue, as: OptionDetailValueResolver

  describe "upsert_option_detail_value/2" do
    test "creates with valid data" do
      %{option: option, option_detail: option_detail, decision: decision} =
        option_detail_value_deps()

      attrs = %{
        value: "foo",
        option_id: option.id,
        option_detail_id: option_detail.id,
        decision: decision
      }

      params = to_graphql_input_params(attrs, decision)

      result = OptionDetailValueResolver.upsert(params, nil)

      assert {:ok, %OptionDetailValue{} = new_record} = result
      assert new_record.value == "foo"

      refute nil == Structure.get_option_detail_value(option.id, option_detail.id, decision.id)
    end

    test "updates with valid data" do
      %{option: option, option_detail: option_detail, decision: decision} =
        create_option_detail_value()

      attrs = %{
        value: "foo",
        option_id: option.id,
        option_detail_id: option_detail.id,
        decision: decision
      }

      params = to_graphql_input_params(attrs, decision)
      result = OptionDetailValueResolver.upsert(params, nil)

      assert {:ok, %OptionDetailValue{} = odv} = result
      assert odv.value == "foo"
    end
  end

  describe "delete/2" do
    test "deletes" do
      %{option: option, option_detail: option_detail, decision: decision} =
        create_option_detail_value()

      attrs = %{
        option_id: option.id,
        option_detail_id: option_detail.id,
        decision: decision
      }

      params = to_graphql_input_params(attrs, decision)

      result = OptionDetailValueResolver.delete(params, nil)

      assert {:ok, %OptionDetailValue{}} = result
      assert nil == Structure.get_option_detail_value(option.id, option_detail.id, decision.id)
    end
  end
end
