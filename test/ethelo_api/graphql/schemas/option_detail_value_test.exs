defmodule EtheloApi.Graphql.Schemas.OptionDetailValueTest do
  @moduledoc """
  Test graphql queries for OptionDetailValues
  """
  use EtheloApi.Graphql.SchemaCase
  @moduletag option_detail_value: true, graphql: true

  alias EtheloApi.Structure
  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.OptionDetailValueHelper

  describe "upsertOptionDetailValue mutation" do
    test "creates with valid data" do
      %{decision: decision, option: option, option_detail: option_detail} =
        option_detail_value_deps()

      attrs = %{
        value: "Moogle",
        option_id: option.id,
        option_detail_id: option_detail.id
      }

      payload = run_mutate_one_query("upsertOptionDetailValue", decision.id, attrs)
      field_names = Map.keys(attrs)

      assert_mutation_success(attrs, payload, fields(field_names))
    end

    test "updates with valid data" do
      %{decision: decision, option: option, option_detail: option_detail} =
        create_option_detail_value()

      attrs = %{
        value: "Moogle",
        option_id: option.id,
        option_detail_id: option_detail.id
      }

      payload = run_mutate_one_query("upsertOptionDetailValue", decision.id, attrs)

      field_names = Map.keys(attrs)
      assert_mutation_success(attrs, payload, fields(field_names))
    end

    test "invalid reference returns errors" do
      %{decision: decision, option: option, option_detail: option_detail} =
        option_detail_value_deps()

      delete_option(option)

      attrs = %{
        value: "Moogle",
        option_id: option.id,
        option_detail_id: option_detail.id
      }

      payload = run_mutate_one_query("upsertOptionDetailValue", decision.id, attrs)

      expected = [%ValidationMessage{code: :foreign, field: "optionId"}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end
  end

  describe "deleteOptionDetailValue mutation" do
    test "deletes" do
      %{decision: decision, option: option, option_detail: option_detail} =
        create_option_detail_value()

      attrs = %{
        option_id: option.id,
        option_detail_id: option_detail.id
      }

      payload =
        run_mutate_one_query("deleteOptionDetailValue", decision.id, attrs, [
          :option_id,
          :option_detail_id
        ])

      assert_mutation_success(%{}, payload, %{})
      assert nil == Structure.get_option_detail_value(option.id, option_detail.id, decision.id)
    end
  end
end
