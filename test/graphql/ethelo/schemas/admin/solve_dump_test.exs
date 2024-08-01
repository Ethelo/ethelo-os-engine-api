defmodule GraphQL.EtheloApi.AdminSchema.SolveDumpTest do
  @moduledoc """
  Test graphql queries for decisions
  """
  use GraphQL.EtheloApi.AdminSchemaCase
  @moduletag option: true, graphql: true

  import Engine.Scenarios.Factory
  import EtheloApi.Structure.Factory

  def fields() do
    %{
      id: :string,
      updated_at: :date, inserted_at: :date,
    }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  describe "decision => SolveDumps query " do
    test "no filter" do
      decision = create_decision()
      %{solve_dump: first} = create_solve_dump(decision)
      %{solve_dump: second} = create_solve_dump(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            solveDumps{
              id
              updatedAt
              insertedAt
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "solveDumps"])
      assert [_, _] = result
      [first_result, second_result] = result |> Enum.sort_by(&(Map.get(&1, "id")))

      assert_equivalent_graphql(first, first_result, fields())
      assert_equivalent_graphql(second, second_result, fields())
    end

    test "filter by id" do
      decision = create_decision()
      %{solve_dump: matching} = create_solve_dump(decision)
      create_solve_dump(decision)

      query = """
        {
          decision(
            decisionId: #{decision.id}
          )
          {
            solveDumps(
              id: #{matching.id}
            ){
              id
            }
          }
        }
      """
      response = evaluate_graphql(query)

      assert {:ok, %{data: data}} = response
      result = get_in(data, ["decision", "solveDumps"])
      assert [%{"id" => id}] = result
      assert to_string(matching.id) == id
    end
  end
end
