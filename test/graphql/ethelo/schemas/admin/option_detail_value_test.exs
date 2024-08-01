defmodule GraphQL.EtheloApi.AdminSchema.OptionDetailValueTest do
  @moduledoc """
  Test graphql queries for decisions
  """
  use GraphQL.EtheloApi.AdminSchemaCase
  @moduletag option_detail_value: true, graphql: true

  alias EtheloApi.Structure
  alias Kronky.ValidationMessage
  import EtheloApi.Structure.Factory

  def fields() do
    %{
      value: :string,
      updated_at: :date, inserted_at: :date,
    }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  describe "updateOptionDetailValue mutation" do

    test "updates existing" do
      %{decision: decision, option: option, option_detail: option_detail} = option_detail_value_deps()
      input = %{
        value: "Moogle",
        option_id: option.id,
        option_detail_id: option_detail.id,
        decision_id: decision.id,
      }
      query = """
        mutation{
          updateOptionDetailValue(
            input: {
              optionId: #{input.option_id}
              optionDetailId: #{input.option_detail_id}
              decisionId: #{input.decision_id}
              value: "#{input.value}"
            }
          )
          {
            successful
            result {
              value
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"updateOptionDetailValue" => payload} = data
      assert_mutation_success(input, payload, fields([:value]))
    end

    test "failure" do
      %{decision: decision, option: option, option_detail: option_detail} = option_detail_value_deps()
      delete_option(option)
      input = %{
        value: "M",
        decision_id: decision.id,
        option_id: option.id,
        option_detail_id: option_detail.id,
      }

      query = """
        mutation{
          updateOptionDetailValue(
            input: {
              optionId: #{input.option_id}
              optionDetailId: #{input.option_detail_id}
              decisionId: #{input.decision_id}
              value: "#{input.value}"
            }
          ){
            successful
            messages {
              field
              message
              code
            }
            result {
              value
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"updateOptionDetailValue" => payload} = data
      expected = %ValidationMessage{
        code: :foreign, field: "optionId", message: "does not exist"
      }
      assert_mutation_failure([expected], payload, [:field, :message, :code])
    end
  end

  describe "deleteOptionDetailValue mutation" do
    test "succeeds" do
      %{decision: decision, option: option, option_detail: option_detail} = create_option_detail_value()
      input = %{
        option_id: option.id,
        option_detail_id: option_detail.id,
        decision_id: decision.id,
      }

      query = """
        mutation{
          deleteOptionDetailValue(
            input: {
              optionId: #{input.option_id}
              optionDetailId: #{input.option_detail_id}
              decisionId: #{input.decision_id}
            }
          ){
            successful
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      assert %{"deleteOptionDetailValue" => %{"successful" => true}} = data
      assert nil == Structure.get_option_detail_value(option.id, option_detail.id, decision.id)
    end
  end
end
