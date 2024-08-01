defmodule GraphQL.EtheloApi.Resolvers.CriteriaTest do
  @moduledoc """
  Validations and basic access for "Criteria" resolver, used to load criteria records
  through graphql.
  Note: Functionality is provided through the CriteriaResolver.Criteria context, so these tests
  will cover a limited amount of cases. For details about edge cases or
  specifics of error messages, please refer to `EtheloApi.Structure.CriteriaTest`

  """
  use EtheloApi.DataCase
  @moduletag criteria: true, graphql: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.CriterionHelper

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Criteria
  alias Ecto.Changeset
  alias GraphQL.EtheloApi.Resolvers.Criteria, as: CriteriaResolver
  alias Kronky.ValidationMessage

  describe "list/2" do
    test "returns all Criterias for a Decision" do
      %{criteria: first, decision: decision} = create_criteria()
      %{criteria: second} = create_criteria(decision)

      parent = %{decision: decision}
      args = %{}
      result = CriteriaResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%Criteria{}, %Criteria{}] = result
      assert_result_ids_match([first, second], result)
    end

    test "filters by Criteria.id" do
      %{criteria: matching, decision: decision} = create_criteria()
      create_criteria(decision)

      parent = %{decision: decision}
      args = %{id: matching.id}
      result = CriteriaResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%Criteria{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by Criteria.slug" do
      %{criteria: matching, decision: decision} = create_criteria()
      create_criteria(decision)

      parent = %{decision: decision}
      args = %{slug: matching.slug}
      result = CriteriaResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%Criteria{}] = result
      assert_result_ids_match([matching], result)
    end

    test "no Criteria matches" do
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
      deps = criteria_deps()
      %{decision: decision} = deps

      attrs = deps |> valid_attrs() |> to_graphql_attrs()
      result = CriteriaResolver.create(decision, attrs)

      assert {:ok, %Criteria{} = new_record} = result
      assert_equivalent(attrs, new_record)
    end

    test "returns a changeset with invalid data" do
      deps = criteria_deps()
      %{decision: decision} = deps

      attrs = deps |> invalid_attrs() |> to_graphql_attrs()
      result = CriteriaResolver.create(decision, attrs)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> errors_on() |> Map.keys()
      assert :title in errors
      assert :slug in errors
      assert :sort in errors
      assert :support_only in errors
      assert :apply_participant_weights in errors
      assert :weighting in errors
    end
  end

  describe "update/2" do

    test "updates with valid data" do
      %{decision: decision, criteria: existing} = create_criteria()

      attrs = valid_attrs(%{decision: decision, criteria: existing})

      result = CriteriaResolver.update(decision, attrs)
      assert {:ok, %Criteria{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "returns errors when Criteria does not exist" do
      deps = create_criteria()
      %{criteria: criteria, decision: decision} = deps
      delete_criteria(criteria.id)

      attrs = deps |> valid_attrs() |> to_graphql_attrs()
      result = CriteriaResolver.update(decision, attrs)

      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "returns errors when Decision does not match" do
      deps = create_criteria()
      decision = create_decision()

      attrs = deps |> valid_attrs() |> to_graphql_attrs()
      result = CriteriaResolver.update(decision, attrs)

      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "returns a changeset with invalid data" do
      deps = create_criteria()
      %{decision: decision} = deps
      attrs = invalid_attrs(deps)
      result = CriteriaResolver.update(decision, attrs)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> errors_on() |> Map.keys()
      assert :title in errors
      assert :slug in errors
      assert :support_only in errors
      assert :apply_participant_weights in errors
      assert :weighting in errors
      assert :sort in errors
    end
  end

  describe "delete/2" do
    test "deletes" do
      %{decision: decision, criteria: _first} = create_criteria()
      %{criteria: second} = create_criteria(decision)

      attrs = %{decision_id: decision.id, id: second.id}
      result = CriteriaResolver.delete(decision, attrs)

      assert {:ok, %Criteria{}} = result
      assert nil == Structure.get_criteria(second.id, decision)
    end

    test "delete/2 does not return errors when Criteria does not exist" do
      %{decision: decision, criteria: existing} = create_criteria()
      delete_criteria(existing.id)

      attrs = %{decision_id: decision.id, id: existing.id}
      result = CriteriaResolver.delete(decision, attrs)

      assert {:ok, nil} = result
    end

    test "returns error if deleting last criteria" do
      %{decision: decision, criteria: existing} = create_criteria()

      attrs = %{decision_id: decision.id, id: existing.id}
      result = CriteriaResolver.delete(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "cannot be deleted" in errors.id
      refute nil == Structure.get_criteria(existing.id, decision)
    end
  end
end
