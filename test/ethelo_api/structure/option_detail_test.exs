defmodule EtheloApi.Structure.OptionDetailTest do
  @moduledoc """
  Validations and basic access for OptionDetails
  Includes both the context EtheloApi.Structure, and specific functionality on the OptionDetail schema
  """
  use EtheloApi.DataCase
  @moduletag option_detail: true, ecto: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.OptionDetailHelper
  alias EtheloApi.Structure
  alias EtheloApi.Structure.OptionDetail
  alias EtheloApi.Structure.Decision

  describe "list_option_details/1" do
    test "filters by decision_id" do
      %{option_detail: _excluded} = create_option_detail()
      %{option_detail: to_match1, decision: decision} = create_option_detail()
      %{option_detail: to_match2} = create_option_detail(decision)

      result = Structure.list_option_details(decision)
      assert [%OptionDetail{}, %OptionDetail{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Structure.list_option_details(nil) end
    end

    test "returns selected fields" do
      %{option_detail: to_match1, decision: decision} = create_option_detail()
      %{option_detail: to_match2} = create_option_detail(decision)

      result = Structure.list_option_details(decision, %{}, [:id, :title])

      assert [%{id: _, title: _}, %{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
    end

    test "filters distinct records" do
      sort_10 = %{sort: 10}
      sort_0 = %{sort: 0}

      decision = create_decision()
      create_option_detail(decision, sort_10)
      create_option_detail(decision, sort_10)
      create_option_detail(decision, sort_0)

      result = Structure.list_option_details(decision, %{distinct: true}, [:sort])

      assert [_, _] = result
      assert sort_10 in result
      assert sort_0 in result
    end

    test "filters by id" do
      %{option_detail: to_match, decision: decision} = create_option_detail()
      %{option_detail: _excluded} = create_option_detail(decision)

      modifiers = %{id: to_match.id}
      result = Structure.list_option_details(decision, modifiers)

      assert [%OptionDetail{}] = result
      assert_result_ids_match([to_match], result)
    end

    test "filters by slug" do
      %{option_detail: to_match, decision: decision} = create_option_detail()
      %{option_detail: _excluded} = create_option_detail(decision)

      modifiers = %{slug: to_match.slug}
      result = Structure.list_option_details(decision, modifiers)

      assert [%OptionDetail{}] = result
      assert_result_ids_match([to_match], result)
    end
  end

  describe "get_option_detail/2" do
    test "filters by decision_id as struct" do
      %{option_detail: to_match, decision: decision} = create_option_detail()

      result = Structure.get_option_detail(to_match.id, decision)

      assert %OptionDetail{} = result
      assert result.id == to_match.id
    end

    test "filters by decision_id" do
      %{option_detail: to_match, decision: decision} = create_option_detail()

      result = Structure.get_option_detail(to_match.id, decision.id)

      assert %OptionDetail{} = result
      assert result.id == to_match.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn -> Structure.get_option_detail(1, nil) end
    end

    test "raises without an OptionDetail id" do
      assert_raise ArgumentError, ~r/OptionDetail/, fn ->
        Structure.get_option_detail(nil, create_decision())
      end
    end

    test "missing record returns nil" do
      decision = create_decision()

      result = Structure.get_option_detail(1929, decision.id)
      assert result == nil
    end

    test "invalid Decision returns nil" do
      %{option_detail: to_match} = create_option_detail()
      decision2 = create_decision()

      result = Structure.get_option_detail(to_match.id, decision2)

      assert result == nil
    end
  end

  describe "create_option_detail/2" do
    test "creates with valid data" do
      deps = option_detail_deps()
      %{decision: decision} = deps
      attrs = valid_attrs(deps)

      result = Structure.create_option_detail(attrs, decision)

      assert {:ok, %OptionDetail{} = new_record} = result

      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/, fn ->
        Structure.create_option_detail(invalid_attrs(), nil)
      end
    end

    test "empty data returns changeset" do
      decision = create_decision()

      result = Structure.create_option_detail(empty_attrs(), decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      expected = [:title, :slug, :format]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "invalid data returns changeset" do
      decision = create_decision()

      attrs = invalid_attrs()
      result = Structure.create_option_detail(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.format
      assert "is invalid" in errors.public
      assert "is invalid" in errors.sort
      expected = [:title, :slug, :format, :public, :sort]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "duplicate title with no slug defined generates variant slug" do
      %{option_detail: existing, decision: decision} = deps = create_option_detail()

      attrs = deps |> valid_attrs() |> Map.put(:title, existing.title) |> Map.drop([:slug])
      result = Structure.create_option_detail(attrs, decision)

      assert {:ok, %OptionDetail{} = new_record} = result

      refute existing.slug == new_record.slug
    end

    test "duplicate slug returns changeset" do
      %{option_detail: existing, decision: decision} = deps = create_option_detail()
      attrs = deps |> valid_attrs() |> Map.put(:slug, existing.slug)

      result = Structure.create_option_detail(attrs, decision)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "update_option_detail/2" do
    test "updates with valid data" do
      %{option_detail: to_update} = deps = create_option_detail()
      attrs = valid_attrs(deps)

      result = Structure.update_option_detail(to_update, attrs)

      assert {:ok, %OptionDetail{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "empty data returns changeset" do
      %{option_detail: to_update} = create_option_detail()

      result = Structure.update_option_detail(to_update, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      expected = [:title, :slug, :format]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "invalid data returns changeset" do
      %{option_detail: to_update} = create_option_detail()

      attrs = invalid_attrs()
      result = Structure.update_option_detail(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "can't be blank" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.format
      assert "is invalid" in errors.sort
      assert "is invalid" in errors.public
      expected = [:title, :slug, :format, :public, :sort]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end

    test "Decision update ignored" do
      %{option_detail: to_update} = create_option_detail()
      decision2 = create_decision()

      attrs = %{public: true, decision: decision2}
      result = Structure.update_option_detail(to_update, attrs)

      assert {:ok, updated} = result
      assert updated.public == attrs.public
      refute updated.decision.id == decision2.id
      assert updated.decision.id == to_update.decision_id
    end

    test "duplicate title with no slug defined does not update slug" do
      %{option_detail: duplicate, decision: decision} = create_option_detail()
      %{option_detail: to_update} = deps = create_option_detail(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, duplicate.title) |> Map.drop([:slug])
      result = Structure.update_option_detail(to_update, attrs)

      assert {:ok, %OptionDetail{} = updated} = result

      assert to_update.slug == updated.slug
    end

    test "duplicate title with nil slug defined generates variant slug" do
      %{option_detail: duplicate, decision: decision} = create_option_detail()
      %{option_detail: to_update} = deps = create_option_detail(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, duplicate.title) |> Map.put(:slug, nil)
      result = Structure.update_option_detail(to_update, attrs)

      assert {:ok, %OptionDetail{} = updated} = result
      refute to_update.slug == updated.slug
      refute to_update.slug == duplicate.slug
    end

    test "duplicate slug returns changeset" do
      %{option_detail: duplicate, decision: decision} = create_option_detail()
      %{option_detail: to_update} = deps = create_option_detail(decision)

      attrs = deps |> valid_attrs() |> Map.put(:slug, duplicate.slug)
      result = Structure.update_option_detail(to_update, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = error_map(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "delete_option_detail/2" do
    test "deletes" do
      %{option_detail: to_delete, decision: decision} = create_option_detail()

      result = Structure.delete_option_detail(to_delete, decision.id)
      assert {:ok, %OptionDetail{}} = result
      assert nil == Repo.get(OptionDetail, to_delete.id)
      assert nil !== Repo.get(Decision, decision.id)
    end
  end

  describe "documentation" do
    test "has documentation module" do
      assert %{} = OptionDetail.strings()
      assert %{} = OptionDetail.examples()
      assert is_list(OptionDetail.fields())
    end
  end
end
