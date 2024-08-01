defmodule EtheloApi.Structure.DecisionTest do
  @moduledoc """
  Validations and basic access for "Decision", the base model all config is attached to
  Includes both the context EtheloApi.Structure, and specific functionality on the Decision schema
  """
  use EtheloApi.DataCase
  @moduletag decision: true, ethelo: true, ecto: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.DecisionHelper

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision

  describe "list_decisions/1" do
    test "list_decisions/1 returns all decisions" do
      first = create_decision()
      second = create_decision()

      result = Structure.list_decisions()
      assert [%Decision{}, %Decision{}] = result
      assert_result_ids_match([first, second], result)
    end

    test "list_decisions/1 filters by id" do
      first = create_decision()
      create_decision()

      result = Structure.list_decisions(%{id: first.id})
      assert [%Decision{} = match] = result
      assert match.id == first.id

      result = Structure.list_decisions(%{id: [first.id, 1000]})
      assert [%Decision{} = match] = result
      assert match.id == first.id
    end

    test "list_decisions/1 filters by slug" do
      first = create_decision()
      create_decision()

      result = Structure.list_decisions(%{slug: first.slug})
      assert [%Decision{} = match] = result
      assert match.id == first.id
    end

    test "list_decisions/1 filters by keywords" do
      first = create_decision(%{keywords: ["foo", "bar"]})
      second = create_decision(%{keywords: ["boo", "far"]})

      result = Structure.list_decisions(%{keywords: ["foo"]})
      assert [%Decision{} = match] = result
      assert match.id == first.id

      # match any
      result = Structure.list_decisions(%{keywords: ["foo", "boo"]})
      assert [%Decision{}, %Decision{}] = result
      assert_result_ids_match([first, second], result)

      # keyword not in db
      result = Structure.list_decisions(%{keywords: ["moo"]})
      assert [] = result

    end
  end

  describe "get_decision/1" do
    test "returns the matching record by id" do
      record = create_decision()
      result = Structure.get_decision(record.id)
      assert %Decision{} = result
      assert result.id == record.id
    end

    test "returns nil if id does not exist" do
      record = create_decision()
      delete_decision(record)

      result = Structure.get_decision(record.id)
      assert result == nil
    end
  end

  describe "create_decision/2 " do

    test "creates with valid data" do
      attrs = valid_attrs()

      result  = Structure.create_decision(attrs)

      assert {:ok, %Decision{} = new_record} = result
      assert_equivalent(attrs, new_record)
    end

    test "upserts default option category" do
      attrs = valid_attrs()

      {:ok, decision} = Structure.create_decision(attrs)

      refute nil == Structure.get_default_option_category(decision)
    end

    test "upserts all options filter" do
      attrs = valid_attrs()

      {:ok, decision} = Structure.create_decision(attrs)

      assert [%{match_mode: "all_options"}] = Structure.list_option_filters(decision.id)
    end

    test "ensures at least one criteria" do
      attrs = valid_attrs()

      {:ok, decision} = Structure.create_decision(attrs)

      assert [_] = Structure.list_criterias(decision)
    end

    test "with empty data returns errors" do
      result =  Structure.create_decision(empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      error_keys = Map.keys(errors)
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      refute :info in error_keys
      refute :copyable in error_keys
      refute :internal in error_keys
      refute :max_users in error_keys
      refute :language in error_keys
      refute :keywords in error_keys
      refute :published_decision_hash in error_keys
      refute :preview_decision_hash in error_keys
      refute :influent_hash in error_keys
      refute :weighting_hash in error_keys

       assert [_, _] = error_keys
    end

    test "with invalid data returns errors" do
      attrs = invalid_attrs()

      result =  Structure.create_decision(attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "must include at least one word" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.copyable
      assert "is invalid" in errors.max_users
      assert "is invalid" in errors.language
      assert "is invalid" in errors.keywords
      refute :info in Map.keys(errors)
      refute :published_decision_hash in Map.keys(errors)
      refute :preview_decision_hash in Map.keys(errors)
      refute :influent_hash in Map.keys(errors)
      refute :weighting_hash in Map.keys(errors)

      assert [_, _, _, _, _, _,] = Map.keys(errors)
    end

    test "a duplicate title with no slug defined generates variant slug" do
      existing = create_decision()

      attrs = valid_attrs() |> Map.put(:title, existing.title) |> Map.drop([:slug])
      result = Structure.create_decision(attrs)

      assert {:ok, %Decision{} = new_record} = result
      refute existing.slug == new_record.slug
    end

    test "a duplicate slug returns errors" do
      existing = create_decision()
      attrs = valid_attrs() |> Map.put(:slug, existing.slug)

      result = Structure.create_decision(attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "update_decision/2" do
    test "updates with valid data" do
      existing = create_decision()

      attrs = valid_attrs()
      result = Structure.update_decision(existing, attrs)

      assert {:ok, %Decision{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "empty data returns errors" do
      existing = create_decision()

      result =  Structure.update_decision(existing, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      error_keys = Map.keys(errors)
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      refute :language in error_keys
      refute :info in error_keys
      refute :published_decision_hash in error_keys
      refute :preview_decision_hash in error_keys
      refute :influent_hash in error_keys
      refute :weighting_hash in error_keys
      assert [_, _,] = Map.keys(errors)

    end

    test "invalid data returns errors" do
      existing = create_decision()

      attrs = invalid_attrs()
      result = Structure.update_decision(existing, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "must include at least one word" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.max_users
      assert "is invalid" in errors.language
      assert "is invalid" in errors.keywords
      refute :info in Map.keys(errors)
      refute :published_decision_hash in Map.keys(errors)
      refute :preview_decision_hash in Map.keys(errors)
      refute :influent_hash in Map.keys(errors)
      refute :weighting_hash in Map.keys(errors)
      assert [_, _, _, _, _, _] = Map.keys(errors)
    end

    test "duplicate title with no slug defined does not update slug" do
      first = create_decision()
      second = create_decision()

      attrs = valid_attrs() |> Map.put(:title, first.title) |> Map.drop([:slug])
      result = Structure.update_decision(second, attrs)

      assert {:ok, %Decision{} = updated} = result
      assert second.slug == updated.slug
    end

    test "duplicate title with nil slug defined generates variant slug" do
      first = create_decision()
      second = create_decision()

      attrs = valid_attrs() |> Map.put(:title, first.title) |> Map.put(:slug, nil)
      result = Structure.update_decision(second, attrs)

      assert {:ok, %Decision{} = updated} = result
      refute second.slug == updated.slug
      refute second.slug == first.slug
    end

    test "duplicate slug returns errors" do
      first = create_decision()
      second = create_decision()

      attrs = valid_attrs() |> Map.put(:slug, first.slug)
      result = Structure.update_decision(second, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "has already been taken" in errors.slug
    end
  end
  describe "delete_decision/1" do
    test "deletes" do
      existing = create_decision()
      to_delete = %Decision{id: existing.id}

      result = Structure.delete_decision(to_delete)
      assert {:ok, %Decision{}} = result
      assert nil == Repo.get(Decision, existing.id)
    end
  end

  describe "documentation" do
    test "has documentation module" do
      assert %{} = Decision.strings()
      assert %{} = Decision.examples()
      assert is_list(Decision.fields())
    end
  end

end
