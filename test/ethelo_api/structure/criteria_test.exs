defmodule EtheloApi.Structure.CriteriaTest do
  @moduledoc """
  Validations and basic access for Criterias
  Includes both the context EtheloApi.Structure, and specific functionality on the Criteria schema
  """
  use EtheloApi.DataCase
  @moduletag criteria: true, ecto: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.CriteriaHelper

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Criteria
  alias EtheloApi.Structure.Decision

  describe "list_criterias/1" do
    test "filters by decision_id" do
      %{criteria: _excluded} = create_criteria()
      %{criteria: to_match1, decision: decision} = create_criteria()
      %{criteria: to_match2} = create_criteria(decision)

      result = Structure.list_criterias(decision)
      assert [%Criteria{}, %Criteria{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
    end

    test "filters by id" do
      %{criteria: to_match, decision: decision} = create_criteria()
      %{criteria: _excluded} = create_criteria(decision)

      modifiers = %{id: to_match.id}
      result = Structure.list_criterias(decision, modifiers)

      assert [%Criteria{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "filters by slug" do
      %{criteria: to_match, decision: decision} = create_criteria()
      %{criteria: _excluded} = create_criteria(decision)

      modifiers = %{slug: to_match.slug}
      result = Structure.list_criterias(decision, modifiers)

      assert [%Criteria{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Structure.list_criterias(nil) end
    end
  end

  describe "get_criteria/2" do
    test "filters by decision_id as struct" do
      %{criteria: to_match, decision: decision} = create_criteria()

      result = Structure.get_criteria(to_match.id, decision)

      assert %Criteria{} = result
      assert result.id == to_match.id
    end

    test "filters by decision_id" do
      %{criteria: to_match, decision: decision} = create_criteria()

      result = Structure.get_criteria(to_match.id, decision.id)

      assert %Criteria{} = result
      assert result.id == to_match.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Structure.get_criteria(1, nil) end
    end

    test "raises without a Criteria id" do
      assert_raise ArgumentError, ~r/Criteria/, fn ->
        Structure.get_criteria(nil, create_decision())
      end
    end

    test "missing record returns nil" do
      decision = create_decision()

      result = Structure.get_criteria(1929, decision.id)
      assert result == nil
    end

    test "invalid Decision returns nil" do
      %{criteria: to_match} = create_criteria()
      decision2 = create_decision()

      result = Structure.get_criteria(to_match.id, decision2)

      assert result == nil
    end
  end

  describe "create_criteria/2" do
    test "creates with valid data" do
      deps = criteria_deps()
      %{decision: decision} = deps
      attrs = valid_attrs(deps)

      result = Structure.create_criteria(attrs, decision)

      assert {:ok, %Criteria{} = new_record} = result

      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn ->
        Structure.create_criteria(invalid_attrs(), nil)
      end
    end

    test "empty data returns changeset" do
      %{decision: decision} = criteria_deps()

      result = Structure.create_criteria(empty_attrs(), decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      assert "can't be blank" in errors.bins
      assert "must have numbers and/or letters" in errors.slug

      expected = [:title, :slug, :bins]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "invalid data returns changeset" do
      decision = create_decision()

      result = Structure.create_criteria(invalid_attrs(), decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.support_only
      assert "is invalid" in errors.apply_participant_weights
      assert "is invalid" in errors.sort
      assert "is invalid" in errors.bins
      assert "is invalid" in errors.info
      assert "must be less than or equal to 9999" in errors.weighting

      expected = [
        :title,
        :slug,
        :support_only,
        :apply_participant_weights,
        :weighting,
        :bins,
        :info,
        :sort
      ]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "duplicate title with no slug defined generates variant slug" do
      %{criteria: existing, decision: decision} = deps = create_criteria()

      attrs = deps |> valid_attrs() |> Map.put(:title, existing.title) |> Map.drop([:slug])
      result = Structure.create_criteria(attrs, decision)

      assert {:ok, %Criteria{} = new_record} = result

      refute existing.slug == new_record.slug
    end

    test "duplicate slug returns changeset" do
      %{criteria: existing, decision: decision} = deps = create_criteria()
      attrs = deps |> valid_attrs() |> Map.put(:slug, existing.slug)

      result = Structure.create_criteria(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "update_criteria/2" do
    test "updates with valid data" do
      deps = create_criteria()
      %{criteria: to_update} = deps

      attrs = valid_attrs(deps)

      result = Structure.update_criteria(to_update, attrs)

      assert {:ok, %Criteria{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "empty data returns changeset" do
      deps = create_criteria()
      %{criteria: to_update} = deps

      result = Structure.update_criteria(to_update, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      assert "can't be blank" in errors.bins
      assert "must have numbers and/or letters" in errors.slug
      expected = [:title, :slug, :bins]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "invalid data returns changeset" do
      %{criteria: to_update} = create_criteria()

      attrs = invalid_attrs()
      result = Structure.update_criteria(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.support_only
      assert "is invalid" in errors.apply_participant_weights
      assert "is invalid" in errors.sort
      assert "must be less than or equal to 9999" in errors.weighting
      assert "is invalid" in errors.bins
      assert "is invalid" in errors.info

      expected = [
        :title,
        :slug,
        :support_only,
        :apply_participant_weights,
        :weighting,
        :bins,
        :info,
        :sort
      ]

      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "Decision update ignored" do
      %{criteria: to_update} = create_criteria()
      decision2 = create_decision()

      attrs = %{weighting: 43, decision: decision2}
      result = Structure.update_criteria(to_update, attrs)

      assert {:ok, updated} = result
      assert updated.weighting == attrs.weighting
      refute updated.decision.id == decision2.id
      assert updated.decision.id == to_update.decision_id
    end

    test "duplicate title with no slug defined does not update slug" do
      %{criteria: duplicate, decision: decision} = create_criteria()
      %{criteria: to_update} = deps = create_criteria(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, duplicate.title) |> Map.drop([:slug])
      result = Structure.update_criteria(to_update, attrs)

      assert {:ok, %Criteria{} = updated} = result

      assert to_update.slug == updated.slug
    end

    test "duplicate title with nil slug defined generates variant slug" do
      %{criteria: duplicate, decision: decision} = create_criteria()
      %{criteria: to_update} = deps = create_criteria(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, duplicate.title) |> Map.put(:slug, nil)
      result = Structure.update_criteria(to_update, attrs)

      assert {:ok, %Criteria{} = updated} = result
      refute to_update.slug == updated.slug
      refute to_update.slug == duplicate.slug
    end

    test "duplicate slug returns changeset" do
      %{criteria: duplicate, decision: decision} = create_criteria()
      %{criteria: to_update} = deps = create_criteria(decision)

      attrs = deps |> valid_attrs() |> Map.put(:slug, duplicate.slug)
      result = Structure.update_criteria(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "delete_criteria/2" do
    test "deletes when is not last" do
      %{criteria: _first, decision: decision} = create_criteria()
      %{criteria: to_delete} = create_criteria(decision)

      result = Structure.delete_criteria(to_delete, decision.id)
      assert {:ok, %Criteria{}} = result
      assert nil == Repo.get(Criteria, to_delete.id)
      assert nil !== Repo.get(Decision, decision.id)
    end

    test "deleting last Criteria returns changeset" do
      %{criteria: last_criteria, decision: decision} = create_criteria()

      result = Structure.delete_criteria(last_criteria, decision.id)
      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "cannot be deleted" in errors.id
      refute nil == Repo.get(Criteria, last_criteria.id)
      assert nil !== Repo.get(Decision, decision.id)
    end
  end

  describe "documentation" do
    test "has documentation module" do
      assert %{} = Criteria.strings()
      assert %{} = Criteria.examples()
      assert is_list(Criteria.fields())
    end
  end
end
