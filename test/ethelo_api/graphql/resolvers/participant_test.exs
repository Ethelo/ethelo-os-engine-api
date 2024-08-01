defmodule EtheloApi.Graphql.Resolvers.ParticipantTest do
  @moduledoc """
  Validations and basic access for Participant resolver
  through graphql.
  Note: Functionality is provided through the ParticipantResolver.Participant context, so these tests
  will cover a limited amount of cases. For details about edge cases or
  specifics of error messages, please refer to `EtheloApi.Voting.ParticipantTest`

  """
  use EtheloApi.DataCase
  @moduletag participant: true, graphql: true

  import EtheloApi.Voting.Factory
  import EtheloApi.Voting.TestHelper.ParticipantHelper
  alias EtheloApi.Voting
  alias EtheloApi.Voting.Participant
  alias EtheloApi.Graphql.Resolvers.Participant, as: ParticipantResolver

  def test_list_filtering(field_name) do
    %{participant: to_match, decision: decision} = create_participant()
    %{participant: _excluded} = create_participant(decision)
    parent = %{decision: decision}
    args = %{} |> Map.put(field_name, Map.get(to_match, field_name))
    result = ParticipantResolver.list(parent, args, nil)

    assert {:ok, result} = result
    assert [%Participant{}] = result
    assert_result_ids_match([to_match], result)
  end

  describe "list/2" do
    test "filters by decision_id" do
      %{participant: duplicate, decision: decision} = create_participant()
      %{participant: to_update} = create_participant(decision)

      parent = %{decision: decision}
      args = %{}
      result = ParticipantResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%Participant{}, %Participant{}] = result
      assert_result_ids_match([duplicate, to_update], result)
    end

    test "filters by id" do
      test_list_filtering(:id)
    end

    test "no matching records" do
      decision = create_decision()

      parent = %{decision: decision}
      args = %{}
      result = ParticipantResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [] = result
    end
  end

  describe "create/2" do
    test "creates with valid data" do
      %{decision: decision} = deps = participant_deps()

      attrs = deps |> valid_attrs()
      params = to_graphql_input_params(attrs, decision)

      result = ParticipantResolver.create(params, nil)
      assert {:ok, %Participant{} = new_record} = result
      assert_equivalent(attrs, new_record)
    end

    test "invalid data returns changeset" do
      %{decision: decision} = deps = participant_deps()

      attrs = deps |> invalid_attrs()
      params = to_graphql_input_params(attrs, decision)
      result = ParticipantResolver.create(params, nil)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> error_map()

      expected = [:weighting]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end
  end

  describe "update/2" do
    test "updates with valid data" do
      %{decision: decision} = deps = create_participant()

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = ParticipantResolver.update(params, nil)
      assert {:ok, %Participant{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "invalid Participant returns error" do
      %{decision: decision, participant: to_delete} = deps = create_participant()
      delete_participant(to_delete.id)

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = ParticipantResolver.update(params, nil)
      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "Decision mismatch returns changeset" do
      deps = create_participant()
      decision = create_decision()
      deps = Map.put(deps, :decision, decision)

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = ParticipantResolver.update(params, nil)
      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "invalid data returns changeset" do
      %{decision: decision} = deps = create_participant()
      attrs = invalid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)
      result = ParticipantResolver.update(params, nil)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> error_map()

      expected = [:weighting]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end
  end

  describe "delete/2" do
    test "deletes" do
      %{decision: decision, participant: to_delete} = create_participant()

      attrs = %{decision_id: decision.id, id: to_delete.id}
      params = to_graphql_input_params(attrs, decision)
      result = ParticipantResolver.delete(params, nil)

      assert {:ok, %Participant{}} = result
      assert nil == Voting.get_participant(to_delete.id, decision)
    end

    test "when record does not exist return successful nil" do
      %{decision: decision, participant: to_delete} = create_participant()
      delete_participant(to_delete.id)

      attrs = %{decision_id: decision.id, id: to_delete.id}
      params = to_graphql_input_params(attrs, decision)
      result = ParticipantResolver.delete(params, nil)

      assert {:ok, nil} = result
    end
  end
end
