defmodule Engine.Scenarios.SolveDumpTest do
  @moduledoc """
  Validations and basic access for SolveDumps
  Includes both the context EtheloApi.SolveDumps, and specific functionality on the SolveDump schema
  """
  use EtheloApi.DataCase
  @moduletag solve_dump: true, ethelo: true, ecto: true
  
  import Engine.Scenarios.Factory

  alias Engine.Scenarios
  alias EtheloApi.Structure.Decision
  alias Engine.Scenarios.SolveDump

  def valid_attrs(%{} = _deps) do
   %{
     decision_json: "{}",
     influents_json: "{}",
     weights_json: "{}",
     config_json: "{}",
     response_json: "{}",
     error: "",
    }
  end

  def assert_equivalent(expected, result) do
    assert expected.decision_json == result.decision_json
    assert expected.influents_json == result.influents_json
    assert expected.weights_json == result.weights_json
    assert expected.config_json == result.config_json
    assert expected.response_json == result.response_json
    assert expected.error == result.error
  end

  describe "list_solve_dumps/1" do

    test "returns records matching a Decision" do
      create_solve_dump() # should not be returned
      %{decision: decision, solve_dump: first} = create_solve_dump()
      %{solve_dump: second} = create_solve_dump(decision)

      result = Scenarios.list_solve_dumps(decision)
      assert [%SolveDump{}, %SolveDump{}] = result
      assert_result_ids_match([first, second], result)
    end

    test "returns record matching id" do
      %{decision: decision, solve_dump: matching} = create_solve_dump()
      create_solve_dump(decision) # should not be returned

      filters = %{id: matching.id}
      result = Scenarios.list_solve_dumps(decision, filters)

      assert [%SolveDump{}] = result
      assert_result_ids_match([matching], result)
    end

    test "returns record matching secnario_set_id" do
      %{decision: decision, solve_dump: matching} = create_solve_dump()
      create_solve_dump(decision) # should not be returned

      filters = %{scenario_set_id: matching.scenario_set_id}
      result = Scenarios.list_solve_dumps(decision, filters)

      assert [%SolveDump{}] = result
      assert_result_ids_match([matching], result)
    end

  end

  describe "delete_solve_dump/2" do

    test "deletes" do
      %{solve_dump: existing, decision: decision} = create_solve_dump()
      create_solve_dump(decision)
      to_delete = %SolveDump{id: existing.id}

      result = Scenarios.delete_solve_dump(to_delete, decision.id)
      assert {:ok, %SolveDump{}} = result
      assert nil == Repo.get(SolveDump, existing.id)
      assert nil !== Repo.get(Decision, decision.id)
    end

  end

  describe "documentation" do
    test "has documentation module" do
      assert %{} = SolveDump.strings()
      assert %{} = SolveDump.examples()
      assert is_list(SolveDump.fields())
    end
  end
end
