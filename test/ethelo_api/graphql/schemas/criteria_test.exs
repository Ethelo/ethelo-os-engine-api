defmodule EtheloApi.Graphql.Schemas.CriteriaTest do
  @moduledoc """
  Test graphql queries for Criterias
  """
  use EtheloApi.Graphql.SchemaCase
  @moduletag criteria: true, graphql: true

  alias EtheloApi.Structure
  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.CriteriaHelper

  describe "decision => criterias query" do
    test "without filter returns all records" do
      %{criteria: to_match1, decision: decision} = create_criteria()
      %{criteria: to_match2} = create_criteria(decision)
      %{criteria: _excluded} = create_criteria()
      assert_list_many_query("criterias", decision.id, %{}, [to_match1, to_match2], fields())
    end

    test "filters by id" do
      %{criteria: to_match, decision: decision} = create_criteria()
      %{criteria: _excluded} = create_criteria(decision)
      assert_list_one_query("criterias", to_match, [:id], fields([:id]))
    end

    test "filters by slug" do
      %{criteria: to_match, decision: decision} = create_criteria()
      %{criteria: _excluded} = create_criteria(decision)
      assert_list_one_query("criterias", to_match, [:slug], fields([:slug]))
    end

    test "no matching records" do
      decision = create_decision()
      assert_list_none_query("criterias", %{decision_id: decision.id}, [:id])
    end
  end

  describe "createCriteria mutation" do
    test "creates with valid data" do
      %{decision: decision} = deps = criteria_deps()

      field_names = input_field_names()
      attrs = deps |> valid_attrs() |> Map.take(field_names)
      requested_fields = Map.keys(attrs) ++ [:id]

      payload = run_mutate_one_query("createCriteria", decision.id, attrs, requested_fields)

      assert_mutation_success(attrs, payload, fields(field_names))
      refute nil == get_in(payload, ["result", "id"])
    end

    test "invalid field returns error" do
      %{decision: decision} = deps = criteria_deps()

      invalid = Map.take(invalid_attrs(), [:title])
      field_names = [:bins, :slug, :title]

      attrs =
        deps
        |> valid_attrs()
        |> Map.merge(invalid)
        |> Map.take(field_names)
        |> Map.take(field_names)

      payload = run_mutate_one_query("createCriteria", decision.id, attrs)

      expected = [%ValidationMessage{code: :required, field: :title}]
      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid Decision returns error" do
      %{decision: decision} = deps = criteria_deps()
      delete_decision(decision)

      field_names = [:bins, :title]
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("createCriteria", decision.id, attrs)

      expected = [%ValidationMessage{code: :not_found, field: "decisionId"}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end
  end

  describe "updateCriteria mutation" do
    test "updates with valid data" do
      %{decision: decision} = deps = create_criteria()

      field_names = input_field_names() ++ [:id]
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("updateCriteria", decision.id, attrs)

      assert_mutation_success(attrs, payload, fields(field_names))
    end

    test "invalid field returns error" do
      %{decision: decision} = deps = create_criteria()

      invalid = Map.take(invalid_attrs(), [:title])
      field_names = [:title, :slug, :id]
      attrs = deps |> valid_attrs() |> Map.merge(invalid) |> Map.take(field_names)

      payload = run_mutate_one_query("updateCriteria", decision.id, attrs)

      expected = [%ValidationMessage{code: :required, field: :title}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end

    test "invalid Criteria returns error" do
      %{criteria: to_delete, decision: decision} = deps = create_criteria()
      delete_criteria(to_delete)

      field_names = [:id, :title]
      attrs = deps |> valid_attrs() |> Map.take(field_names)

      payload = run_mutate_one_query("updateCriteria", decision.id, attrs)

      expected = [%ValidationMessage{code: "not_found", field: :id}]

      assert_mutation_failure(expected, payload, [:field, :code])
    end
  end

  describe "deleteCriteria mutation" do
    test "deletes when is not only criteria" do
      %{decision: decision, criteria: _first} = create_criteria()
      %{criteria: to_delete} = create_criteria(decision)

      attrs = to_delete |> Map.take([:id])

      payload = run_mutate_one_query("deleteCriteria", decision.id, attrs)

      assert_mutation_success(%{}, payload, %{})
      assert nil == Structure.get_criteria(to_delete.id, decision)
    end

    test "cannot delete last criteria" do
      %{decision: decision, criteria: last_criteria} = create_criteria()

      attrs = last_criteria |> Map.take([:id])

      payload = run_mutate_one_query("deleteCriteria", decision.id, attrs)

      expected = [%ValidationMessage{code: :protected_record, field: :id}]
      assert_mutation_failure(expected, payload, [:field, :code])
      refute nil == Structure.get_criteria(last_criteria.id, decision)
    end
  end
end
