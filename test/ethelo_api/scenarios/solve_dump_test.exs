defmodule EtheloApi.Scenarios.SolveDumpTest do
  @moduledoc """
  Validations and basic access for SolveDumps
  Includes both the context EtheloApi.SolveDumps, and specific functionality on the SolveDump schema
  """
  use EtheloApi.DataCase
  @moduletag solve_dump: true, ecto: true

  import EtheloApi.Scenarios.Factory
  import EtheloApi.Voting.Factory
  import EtheloApi.Scenarios.TestHelper.SolveDumpHelper

  alias EtheloApi.Scenarios
  alias EtheloApi.Scenarios.SolveDump

  describe "get_solve_dump/1" do
    test "gets by ScenarioSet" do
      %{scenario_set: scenario_set, solve_dump: to_match} =
        create_solve_dump()

      result = Scenarios.get_solve_dump(scenario_set)
      assert %SolveDump{} = result
      assert to_match.id == result.id
    end
  end

  describe "upsert_solve_dump/2" do
    test "creates with valid data" do
      %{decision: decision} = deps = solve_dump_deps()
      attrs = valid_attrs(deps)

      result = Scenarios.upsert_solve_dump(attrs)

      assert {:ok, %SolveDump{} = new_record} = result

      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "Duplicate dependencies upserts" do
      deps = create_solve_dump()
      attrs = valid_attrs(deps)

      result = Scenarios.upsert_solve_dump(attrs)

      assert {:ok, %SolveDump{} = updated_record} = result

      assert_equivalent(attrs, updated_record)
      assert updated_record.decision_id == attrs.decision_id
      assert updated_record.scenario_set_id == attrs.scenario_set_id
      assert updated_record.id == deps.solve_dump.id
    end

    test "empty data returns changeset" do
      result = Scenarios.upsert_solve_dump(empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.scenario_set_id
      assert "is invalid" in errors.error
      assert "is invalid" in errors.decision_json
      assert "is invalid" in errors.influents_json
      assert "is invalid" in errors.weights_json
      assert "is invalid" in errors.config_json
      assert "is invalid" in errors.response_json
      assert "can't be blank" in errors.decision_id

      expected = [
        :error,
        :scenario_set_id,
        :decision_json,
        :influents_json,
        :weights_json,
        :config_json,
        :response_json,
        :decision_id
      ]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "invalid data returns changeset" do
      decision = create_decision()
      attrs = invalid_attrs(%{decision: decision})

      result = Scenarios.upsert_solve_dump(attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.scenario_set_id
      assert "is invalid" in errors.error
      assert "is invalid" in errors.decision_json
      assert "is invalid" in errors.influents_json
      assert "is invalid" in errors.weights_json
      assert "is invalid" in errors.config_json
      assert "is invalid" in errors.response_json

      expected = [
        :error,
        :decision_json,
        :influents_json,
        :weights_json,
        :config_json,
        :response_json,
        :scenario_set_id
      ]

      assert {[], []} = error_diff(expected, Map.keys(errors))
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
