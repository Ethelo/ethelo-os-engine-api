defmodule GraphQL.EtheloApi.Resolvers.DecisionTest do
  @moduledoc """
  Validations and basic access for "Decision" resolver, used to load decision records
  through graphql.
  Note: Functionality is provided through the DecisionResolver.Decision context, so these tests
  will cover a limited amount of cases. For details about edge cases or
  specifics of error messages, please refer to `EtheloApi.Structure.DecisionTest`

  """
  use EtheloApi.DataCase
  @moduletag decision: true, graphql: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.DecisionHelper
  alias Kronky.ValidationMessage
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  alias Ecto.Changeset
  alias GraphQL.EtheloApi.Resolvers.Decision, as: DecisionResolver


  describe "list/2" do
    test "returns all decisions" do
      first = create_decision()
      second = create_decision()

      params = %{}
      result = DecisionResolver.list(params, nil)

      assert {:ok, result} = result
      assert [%Decision{}, %Decision{}] = result
      assert_result_ids_match([first, second], result)
    end

    test "filters by decision.id" do
      matching = create_decision()
      create_decision()

      params = %{id: matching.id}
      result = DecisionResolver.list(params, nil)

      assert {:ok, result} = result
      assert [%Decision{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by decision.slug" do
      matching = create_decision()
      create_decision()

      params = %{slug: matching.slug}
      result = DecisionResolver.list(params, nil)

      assert {:ok, result} = result
      assert [%Decision{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by decision.keywords" do
      matching = create_decision(%{keywords: ["foo"] })
      create_decision(%{keywords: ["foo_bar"] }) # not an exact match
      create_decision()

      params = %{keywords: ["foo"]}
      result = DecisionResolver.list(params, nil)

      assert {:ok, result} = result
      assert [%Decision{}] = result
      assert_result_ids_match([matching], result)
    end
  end

  describe "get/2" do

    test "returns the Decision with decision_id value" do
      decision = create_decision()

      params =  %{decision_id: decision.id}
      result = DecisionResolver.get(params, nil)

      assert {:ok, decision_result} = result
      assert decision_result.id == decision.id
    end

    test "returns the Decision with decision_id value when there is an id value in params" do
      decision = create_decision()
      decision2 = create_decision()

      params = %{decision_id: decision.id, id: decision2.id}
      result = DecisionResolver.get(params, nil)

      assert {:ok, decision_result} = result
      assert decision_result.id == decision.id
    end

    test "returns the Decision there is a decision id in the input object" do
      decision = create_decision()

      params = %{input: %{decision_id: decision.id}}
      result = DecisionResolver.get(params, nil)

      assert {:ok, decision_result} = result
      assert decision_result.id == decision.id
    end

    test "returns the Decision there is an id in the input object" do
      decision = create_decision()

      params = %{input: %{id: decision.id}}
      result = DecisionResolver.get(params, nil)

      assert {:ok, decision_result} = result
      assert decision_result.id == decision.id
    end

    test "returns the Decision with input decision_id value when there is an input id value" do
      decision = create_decision()
      decision2 = create_decision()

      params = %{input: %{decision_id: decision.id, id: decision2.id}}
      result = DecisionResolver.get(params, nil)

      assert {:ok, decision_result} = result
      assert decision_result.id == decision.id
    end

    test "returns the Decision with given id" do
      decision = create_decision()

      params = %{id: decision.id}
      result = DecisionResolver.get(params, nil)

      assert {:ok, decision_result} = result
      assert decision_result.id == decision.id
    end

    test "returns an error tuple if Decision does not exist" do
      delete_decision(1)

      params = %{id: 1}
      result = DecisionResolver.get(params, nil)

      assert {:error, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: "id"} = message
    end
  end

  describe "create/2" do

    test "creates with valid data" do
      params = %{input: valid_attrs()}
      result = DecisionResolver.create(params, nil)

      assert {:ok, %Decision{} = decision} = result
      assert_equivalent(params.input, decision)
    end

    test "returns a changeset with invalid data" do
      params = %{input: invalid_attrs()}
      result = DecisionResolver.create(params, nil)

      assert {:ok, %Ecto.Changeset{} = changeset} = result
      errors = changeset |> errors_on() |> Map.keys()
      assert :title in errors
      assert :slug in errors
      assert :language in errors
      assert :copyable in errors
      assert :max_users in errors
      assert :keywords in errors
      assert [_, _, _, _, _, _] = errors
    end
  end

  describe "update/2" do

    test "updates with valid data" do
      decision = create_decision()

      attrs = valid_attrs()
      result = DecisionResolver.update(decision, attrs)

      assert {:ok, %Decision{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "returns a changeset with invalid data" do
      decision = create_decision()

      attrs = invalid_attrs() |> Map.put(:id, decision.id)
      result = DecisionResolver.update(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = changeset |> errors_on() |> Map.keys()
      assert :title in errors
      assert :slug in errors
      assert :language in errors
      assert :copyable in errors
      assert :max_users in errors
      assert :keywords in errors
      assert [_, _, _, _, _, _] = errors    end
  end

  describe "delete/2" do

    test "deletes record" do
      existing = create_decision()

      result = DecisionResolver.delete(nil, %{id: existing.id})

      assert {:ok, %Decision{}} = result
      assert nil == Structure.get_decision(existing.id)
    end

    test "does not return errors when decision does not exist" do
      existing = create_decision()
      delete_decision(existing)
      attrs = %{id: existing.id}

      result = DecisionResolver.delete(nil, attrs)
      assert {:ok, nil} = result
    end
  end
end
