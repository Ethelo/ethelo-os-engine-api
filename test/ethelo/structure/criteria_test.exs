defmodule EtheloApi.Structure.CriteriaTest do
  @moduledoc """
  Validations and basic access for Criterias
  Includes both the context EtheloApi.Structure, and specific functionality on the Criteria schema
  """
  use EtheloApi.DataCase
  @moduletag criteria: true, ethelo: true, ecto: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.CriterionHelper

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Criteria
  alias EtheloApi.Structure.Decision

  describe "list_criterias/1" do

    test "returns all records matching a Decision" do
      create_criteria() # should not be returned
      %{criteria: first, decision: decision} = create_criteria()
      %{criteria: second} = create_criteria(decision)

      result = Structure.list_criterias(decision)
      assert [%Criteria{}, %Criteria{}] = result
      assert_result_ids_match([first, second], result)
    end

    test "returns record matching id" do
      %{criteria: matching, decision: decision} = create_criteria()
      %{criteria: _not_matching} = create_criteria(decision)

      filters = %{id: matching.id}
      result = Structure.list_criterias(decision, filters)

      assert [%Criteria{}] = result
      assert_result_ids_match([matching], result)
    end

    test "returns record matching slug" do
      %{criteria: matching, decision: decision} = create_criteria()
      %{criteria: _not_matching} = create_criteria(decision)

      filters = %{slug: matching.slug}
      result = Structure.list_criterias(decision, filters)

      assert [%Criteria{}] = result
      assert_result_ids_match([matching], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Structure.list_criterias(nil) end
    end
  end

  describe "get_criteria/2" do

    test "returns the matching record by Decision object" do
      %{criteria: record, decision: decision} = create_criteria()

      result = Structure.get_criteria(record.id, decision)

      assert %Criteria{} = result
      assert result.id == record.id
    end

    test "returns the matching record by Decision.id" do
      %{criteria: record, decision: decision} = create_criteria()

      result = Structure.get_criteria(record.id, decision.id)

      assert %Criteria{} = result
      assert result.id == record.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Structure.get_criteria(1, nil) end
    end

    test "raises without a Criteria id" do
      assert_raise ArgumentError, ~r/Criteria/,
        fn -> Structure.get_criteria(nil, create_decision()) end
    end

    test "returns nil if id does not exist" do
      decision = create_decision()

      result = Structure.get_criteria(1929, decision.id)
      assert result == nil
    end

    test "returns nil with invalid decision id " do
      %{criteria: record} = create_criteria()
      decision2 = create_decision()

      result = Structure.get_criteria(record.id, decision2)

      assert result == nil
    end
  end

  describe "create_criteria/2 " do

    test "creates with valid data" do
      deps = criteria_deps()
      %{decision: decision} = deps
      attrs = valid_attrs(deps)

      result = Structure.create_criteria(decision, attrs)

      assert {:ok, %Criteria{} = new_record} = result

      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Structure.create_criteria(nil, invalid_attrs()) end
    end

    test "with empty data returns errors" do
      %{decision: decision} = criteria_deps()

      result = Structure.create_criteria(decision, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "can't be blank" in errors.title
      assert "can't be blank" in errors.bins
      refute :support_only in Map.keys(errors)
      refute :apply_participant_weights in Map.keys(errors)
      refute :weighting in Map.keys(errors)
      refute :sort in Map.keys(errors)
      assert [_, _, _] = Map.keys(errors)
    end

    test "with invalid data returns errors" do
      decision = create_decision()

      result = Structure.create_criteria(decision, invalid_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "must include at least one word" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.support_only
      assert "is invalid" in errors.apply_participant_weights
      assert "is invalid" in errors.sort
      assert "is invalid" in errors.bins
      assert "is invalid" in errors.info
      assert "must be less than or equal to 9999" in errors.weighting
      [_, _, _, _, _, _, _, _] = Map.keys(errors)
    end

    test "a duplicate title with no slug defined generates variant slug" do
      %{criteria: existing, decision: decision} = deps = create_criteria()

      attrs = deps |> valid_attrs() |> Map.put(:title, existing.title) |> Map.drop([:slug])
      result = Structure.create_criteria(decision, attrs)

      assert {:ok, %Criteria{} = new_record} = result

      refute existing.slug == new_record.slug
    end

    test "duplicate slug returns errors" do
      %{criteria: existing, decision: decision} = deps = create_criteria()
      attrs = deps |> valid_attrs() |> Map.put(:slug, existing.slug)

      result = Structure.create_criteria(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "update_criteria/2" do
    test "updates with valid data" do
      deps = create_criteria()
      %{criteria: existing} = deps

      attrs = valid_attrs(deps)

      result = Structure.update_criteria(existing, attrs)

      assert {:ok, %Criteria{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "empty data returns errors" do
      deps = create_criteria()
      %{criteria: existing} = deps

      result = Structure.update_criteria(existing, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "can't be blank" in errors.title
      assert "can't be blank" in errors.bins
      assert "must have numbers and/or letters" in errors.slug
      refute :support_only in Map.keys(errors)
      refute :apply_participant_weights in Map.keys(errors)
      refute :sort in Map.keys(errors)
      refute :weighting in Map.keys(errors)
      assert "must have numbers and/or letters" in errors.slug
      assert [_, _, _] = Map.keys(errors)
    end

    test "invalid data returns errors" do
      %{criteria: existing} = create_criteria()

      attrs = invalid_attrs()
      result = Structure.update_criteria(existing, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "must include at least one word" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.support_only
      assert "is invalid" in errors.apply_participant_weights
      assert "is invalid" in errors.sort
      assert "must be less than or equal to 9999" in errors.weighting
      assert "is invalid" in errors.bins
      assert "is invalid" in errors.info
      assert [_, _, _, _, _, _, _, _] = Map.keys(errors)
    end

    test "Decision update ignored" do
      %{criteria: existing} = create_criteria()
      decision2 = create_decision()

      attrs = %{weighting: 43, decision: decision2}
      result = Structure.update_criteria(existing, attrs)

      assert {:ok, updated} = result
      assert updated.weighting == attrs.weighting
      refute updated.decision.id == decision2.id
      assert updated.decision.id == existing.decision_id
    end

    test "duplicate title with no slug defined does not update slug" do
      %{criteria: first, decision: decision} = create_criteria()
      %{criteria: second} = deps = create_criteria(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, first.title) |> Map.drop([:slug])
      result = Structure.update_criteria(second, attrs)

      assert {:ok, %Criteria{} = updated} = result

      assert second.slug == updated.slug
    end

    test "duplicate title with nil slug defined generates variant slug" do
      %{criteria: first, decision: decision} = create_criteria()
      %{criteria: second} = deps = create_criteria(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, first.title) |> Map.put(:slug, nil)
      result = Structure.update_criteria(second, attrs)

      assert {:ok, %Criteria{} = updated} = result
      refute second.slug == updated.slug
      refute second.slug == first.slug
    end

    test "duplicate slug returns errors" do
      %{criteria: first, decision: decision} = create_criteria()
      %{criteria: second} = deps = create_criteria(decision)

      attrs = deps |> valid_attrs() |> Map.put(:slug, first.slug)
      result = Structure.update_criteria(second, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "delete_criteria/2" do

    test "deletes" do
      %{criteria: _first, decision: decision} = create_criteria()
      %{criteria: second} = create_criteria(decision)
      to_delete = %Criteria{id: second.id}

      result = Structure.delete_criteria(to_delete, decision.id)
      assert {:ok, %Criteria{}} = result
      assert nil == Repo.get(Criteria, second.id)
      assert nil !== Repo.get(Decision, decision.id)
    end

    test "deleting last Criteria returns error" do
      %{criteria: existing, decision: decision} = create_criteria()
      to_delete = %Criteria{id: existing.id}

      result = Structure.delete_criteria(to_delete, decision.id)
      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "cannot be deleted" in errors.id
      refute nil == Repo.get(Criteria, existing.id)
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
