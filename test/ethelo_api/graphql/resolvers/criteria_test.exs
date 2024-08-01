defmodule EtheloApi.Graphql.Resolvers.CriteriaTest do
  @moduledoc """
  Validations and basic access for Criteria resolver
  through graphql.
  Note: Functionality is provided through the CriteriaResolver.Criteria context, so these tests
  will cover a limited amount of cases. For details about edge cases or
  specifics of error messages, please refer to `EtheloApi.Structure.CriteriaTest`

  """
  use EtheloApi.DataCase
  @moduletag criteria: true, graphql: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.CriteriaHelper

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Criteria
  alias EtheloApi.Graphql.Resolvers.Criteria, as: CriteriaResolver

  def test_list_filtering(field_name) do
    %{criteria: to_match, decision: decision} = create_criteria()
    %{criteria: _excluded} = create_criteria(decision)

    parent = %{decision: decision}
    args = %{} |> Map.put(field_name, Map.get(to_match, field_name))
    result = CriteriaResolver.list(parent, args, nil)
    assert {:ok, result} = result
    assert [%Criteria{}] = result
    assert_result_ids_match([to_match], result)
  end

  describe "list/2" do
    test "filters by decision_id" do
      %{criteria: to_match1, decision: decision} = create_criteria()
      %{criteria: to_match2} = create_criteria(decision)
      %{criteria: _excluded} = create_criteria()

      parent = %{decision: decision}
      args = %{}
      result = CriteriaResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%Criteria{}, %Criteria{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
    end

    test "filters by id" do
      test_list_filtering(:id)
    end

    test "filters by slug" do
      test_list_filtering(:slug)
    end

    test "no matching records" do
      decision = create_decision()

      parent = %{decision: decision}
      args = %{}
      result = CriteriaResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [] = result
    end
  end

  describe "create/2" do
    test "creates with valid data" do
      %{decision: decision} = deps = criteria_deps()

      attrs = deps |> valid_attrs()
      params = to_graphql_input_params(attrs, decision)

      result = CriteriaResolver.create(params, nil)
      assert {:ok, %Criteria{} = new_record} = result
      assert_equivalent(attrs, new_record)
    end

    test "invalid data returns changeset" do
      %{decision: decision} = deps = criteria_deps()

      attrs = deps |> invalid_attrs()
      params = to_graphql_input_params(attrs, decision)
      result = CriteriaResolver.create(params, nil)

      assert {:error, %Changeset{} = changeset} = result

      errors = changeset |> error_map()

      expected = [
        :apply_participant_weights,
        :bins,
        :info,
        :slug,
        :sort,
        :support_only,
        :title,
        :weighting
      ]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end
  end

  describe "update/2" do
    test "updates with valid data" do
      %{decision: decision} = deps = create_criteria()

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = CriteriaResolver.update(params, nil)
      assert {:ok, %Criteria{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "invalid Criteria returns error" do
      %{decision: decision, criteria: to_delete} = deps = create_criteria()
      delete_criteria(to_delete.id)

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = CriteriaResolver.update(params, nil)
      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "Decision mismatch returns changeset" do
      deps = create_criteria()
      decision = create_decision()
      deps = Map.put(deps, :decision, decision)

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = CriteriaResolver.update(params, nil)
      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "invalid data returns changeset" do
      %{decision: decision} = deps = create_criteria()
      attrs = invalid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)
      result = CriteriaResolver.update(params, nil)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> error_map()

      expected = [
        :apply_participant_weights,
        :bins,
        :info,
        :slug,
        :sort,
        :support_only,
        :title,
        :weighting
      ]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end
  end

  describe "delete/2" do
    test "deletes when not first" do
      %{decision: decision, criteria: _first} = create_criteria()
      %{criteria: to_delete} = create_criteria(decision)

      attrs = %{decision_id: decision.id, id: to_delete.id}
      params = to_graphql_input_params(attrs, decision)
      result = CriteriaResolver.delete(params, nil)

      assert {:ok, %Criteria{}} = result
      assert nil == Structure.get_criteria(to_delete.id, decision)
    end

    test "when record does not exist return successful nil" do
      %{decision: decision, criteria: to_delete} = create_criteria()
      delete_criteria(to_delete.id)

      attrs = %{decision_id: decision.id, id: to_delete.id}
      params = to_graphql_input_params(attrs, decision)
      result = CriteriaResolver.delete(params, nil)

      assert {:ok, nil} = result
    end

    test "deleting last Criteria returns changeset" do
      %{decision: decision, criteria: last_criteria} = create_criteria()

      attrs = %{decision_id: decision.id, id: last_criteria.id}
      params = to_graphql_input_params(attrs, decision)
      result = CriteriaResolver.delete(params, nil)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "cannot be deleted" in errors.id
      refute nil == Structure.get_criteria(last_criteria.id, decision)
    end
  end
end
