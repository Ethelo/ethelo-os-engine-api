defmodule EtheloApi.Structure.DecisionTest do
  @moduledoc """
  Validations and basic access for "Decision", the base model all config is attached to
  Includes both the context EtheloApi.Structure, and specific functionality on the Decision schema
  """
  use EtheloApi.DataCase
  @moduletag decision: true, ecto: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.DecisionHelper

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision

  describe "list_decisions/1" do
    test "no filter returns all records" do
      to_match1 = create_decision()
      to_match2 = create_decision()

      result = Structure.list_decisions()
      assert [%Decision{}, %Decision{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
    end

    test "filters by id" do
      to_match = create_decision()
      create_decision()

      result = Structure.list_decisions(%{id: to_match.id})
      assert [%Decision{} = match] = result
      assert match.id == to_match.id

      result = Structure.list_decisions(%{id: [to_match.id, 1000]})
      assert [%Decision{} = match] = result
      assert match.id == to_match.id
    end

    test "filters by slug" do
      to_match = create_decision()
      create_decision()

      result = Structure.list_decisions(%{slug: to_match.slug})
      assert [%Decision{} = match] = result
      assert match.id == to_match.id
    end

    test "filters by keywords" do
      to_match1 = create_decision(%{keywords: ["foo", "bar"]})
      to_match2 = create_decision(%{keywords: ["boo", "far"]})

      result = Structure.list_decisions(%{keywords: ["foo"]})
      assert [%Decision{} = match] = result
      assert match.id == to_match1.id

      # match any
      result = Structure.list_decisions(%{keywords: ["foo", "boo"]})
      assert [%Decision{}, %Decision{}] = result
      assert_result_ids_match([to_match1, to_match2], result)

      # keyword not in db
      result = Structure.list_decisions(%{keywords: ["moo"]})
      assert [] = result
    end
  end

  describe "get_decision/1" do
    test "filters by id" do
      to_match = create_decision()
      result = Structure.get_decision(to_match.id)
      assert %Decision{} = result
      assert result.id == to_match.id
    end

    test "missing record returns nil" do
      to_match = create_decision()
      delete_decision(to_match)

      result = Structure.get_decision(to_match.id)
      assert result == nil
    end
  end

  describe "create_decision/2" do
    test "creates with valid data" do
      attrs = valid_attrs()

      result = Structure.create_decision(attrs)

      assert {:ok, %Decision{} = new_record} = result
      assert_equivalent(attrs, new_record)
    end

    test "empty data returns changeset" do
      result = Structure.create_decision(empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug

      expected = [:title, :slug]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "invalid data returns changeset" do
      attrs = invalid_attrs()

      result = Structure.create_decision(attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.copyable
      assert "is invalid" in errors.max_users
      assert "is invalid" in errors.language
      assert "is invalid" in errors.keywords

      expected = [:title, :slug, :copyable, :max_users, :language, :keywords]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "duplicate title with no slug defined generates variant slug" do
      existing = create_decision()

      attrs = valid_attrs() |> Map.put(:title, existing.title) |> Map.drop([:slug])
      result = Structure.create_decision(attrs)

      assert {:ok, %Decision{} = new_record} = result
      refute existing.slug == new_record.slug
    end

    test "duplicate slug returns changeset" do
      existing = create_decision()
      attrs = valid_attrs() |> Map.put(:slug, existing.slug)

      result = Structure.create_decision(attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "has already been taken" in errors.slug
    end

    test "upserts default OptionCategory" do
      attrs = valid_attrs()

      {:ok, decision} = Structure.create_decision(attrs)

      refute nil == Structure.get_default_option_category(decision)
    end

    test "upserts all options filter" do
      attrs = valid_attrs()

      {:ok, decision} = Structure.create_decision(attrs)

      assert [%{match_mode: "all_options"}] = Structure.list_option_filters(decision.id)
    end

    test "ensures at least one Criteria" do
      attrs = valid_attrs()

      {:ok, decision} = Structure.create_decision(attrs)

      assert [_] = Structure.list_criterias(decision)
    end
  end

  describe "update_decision/2" do
    test "updates with valid data" do
      to_update = create_decision()

      attrs = valid_attrs()
      result = Structure.update_decision(to_update, attrs)

      assert {:ok, %Decision{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "empty data returns changeset" do
      to_update = create_decision()

      result = Structure.update_decision(to_update, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      expected = [:title, :slug]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "invalid data returns changeset" do
      to_update = create_decision()

      attrs = invalid_attrs()
      result = Structure.update_decision(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.max_users
      assert "is invalid" in errors.language
      assert "is invalid" in errors.keywords
      assert "is invalid" in errors.copyable
      expected = [:title, :slug, :max_users, :language, :keywords, :copyable]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "duplicate title with no slug defined does not update slug" do
      duplicate = create_decision()
      to_update = create_decision()

      attrs = valid_attrs() |> Map.put(:title, duplicate.title) |> Map.drop([:slug])
      result = Structure.update_decision(to_update, attrs)

      assert {:ok, %Decision{} = updated} = result
      assert to_update.slug == updated.slug
    end

    test "duplicate title with nil slug defined generates variant slug" do
      duplicate = create_decision()
      to_update = create_decision()

      attrs = valid_attrs() |> Map.put(:title, duplicate.title) |> Map.put(:slug, nil)
      result = Structure.update_decision(to_update, attrs)

      assert {:ok, %Decision{} = updated} = result
      refute to_update.slug == updated.slug
      refute to_update.slug == duplicate.slug
    end

    test "duplicate slug returns changeset" do
      duplicate = create_decision()
      to_update = create_decision()

      attrs = valid_attrs() |> Map.put(:slug, duplicate.slug)
      result = Structure.update_decision(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "delete_decision/1" do
    test "deletes" do
      to_delete = create_decision()

      result = Structure.delete_decision(to_delete)
      assert {:ok, %Decision{}} = result
      assert nil == Repo.get(Decision, to_delete.id)
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
