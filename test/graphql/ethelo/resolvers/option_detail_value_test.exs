defmodule GraphQL.EtheloApi.Resolvers.OptionDetailValueTest do
  @moduledoc """
  Validations and basic access for "OptionDetailValue" resolver, used to load OptionDetailValue records
  through graphql.
  Note: Functionality is provided through the Structure context, so these tests
  will cover a limited amount of cases. For details about edge cases or
  specifics of error messages, please refer to `EtheloApi.Structure.OptionDetailValueTest`

  """
  use EtheloApi.DataCase
  import EtheloApi.Structure.Factory
  @moduletag option_detail_value: true, graphql: true

  alias EtheloApi.Structure
  alias EtheloApi.Structure.OptionDetailValue
  alias GraphQL.EtheloApi.Resolvers.OptionDetailValue, as: OptionDetailValueResolver

  describe "update_option_detail_value/2" do

    test "updates existing" do
      %{option: option, option_detail: option_detail, decision: decision} = create_option_detail_value()

      attrs = %{
        value: "foo",
        option_id: option.id,
        option_detail_id: option_detail.id,
        decision_id: decision.id,
      }

      result = OptionDetailValueResolver.update(decision, attrs)


      assert {:ok, %OptionDetailValue{} = odv} = result
      assert odv.value == "foo"
    end

    test "creates new" do
      %{option: option, option_detail: option_detail, decision: decision} = option_detail_value_deps()

      attrs = %{
        value: "foo",
        option_id: option.id,
        option_detail_id: option_detail.id,
        decision_id: decision.id,
      }

      result = OptionDetailValueResolver.update(decision, attrs)

      assert {:ok, %OptionDetailValue{} = odv} = result
      assert odv.value == "foo"

      refute nil == Structure.get_option_detail_value(option.id, option_detail.id, decision.id)
    end
  end

  describe "delete_option_detail_value/2" do
    test "deletes" do
      %{option: option, option_detail: option_detail, decision: decision} = create_option_detail_value()

      attrs = %{
        option_id: option.id,
        option_detail_id: option_detail.id,
        decision_id: decision.id,
      }

      result = OptionDetailValueResolver.delete(decision, attrs)

      assert {:ok, %OptionDetailValue{}} = result
      assert nil == Structure.get_option_detail_value(option.id, option_detail.id, decision.id)
    end
  end
end
