defmodule EtheloApi.Structure.OptionDetailTest do
  @moduledoc """
  Validations and basic access for OptionDetails
  Includes both the context EtheloApi.Structure, and specific functionality on the OptionDetail schema
  """
  use EtheloApi.DataCase
  @moduletag option_detail: true, ethelo: true, ecto: true

 import EtheloApi.Structure.Factory
 import EtheloApi.Structure.TestHelper.OptionDetailHelper
  alias EtheloApi.Structure
  alias EtheloApi.Structure.OptionDetail
  alias EtheloApi.Structure.Decision

  describe "list_option_details/1" do

    test "returns all records matching a Decision" do
      create_option_detail() # should not be returned
      %{option_detail: first, decision: decision} = create_option_detail()
      %{option_detail: second} = create_option_detail(decision)

      result = Structure.list_option_details(decision)
      assert [%OptionDetail{}, %OptionDetail{}] = result
      assert_result_ids_match([first, second], result)
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Structure.list_option_details(nil) end
    end

    test "returns selected fields" do
      %{option_detail: first, decision: decision} = create_option_detail()
      %{option_detail: second} = create_option_detail(decision)
      %{option_detail: third} = create_option_detail()

      result = Structure.list_option_details(decision, %{}, [:id, :title])

      assert [%{id: _, title: _}, %{}] = result
      assert_result_ids_match([first, second], result)
      refute_id_in_result(third.id, result)
    end

    test "returns distinct records" do
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

  end

  describe "get_option_detail/2" do

    test "returns the matching record by Decision object" do
      %{option_detail: record, decision: decision} = create_option_detail()

      result = Structure.get_option_detail(record.id, decision)

      assert %OptionDetail{} = result
      assert result.id == record.id
    end

    test "returns the matching record by Decision.id" do
      %{option_detail: record, decision: decision} = create_option_detail()

      result = Structure.get_option_detail(record.id, decision.id)

      assert %OptionDetail{} = result
      assert result.id == record.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Structure.get_option_detail(1, nil) end
    end

    test "raises without an OptionDetail id" do
      assert_raise ArgumentError, ~r/OptionDetail/,
        fn -> Structure.get_option_detail(nil, create_decision()) end
    end

    test "returns nil if id does not exist" do
      decision = create_decision()

      result = Structure.get_option_detail(1929, decision.id)
      assert result == nil
    end

    test "returns nil with invalid decision id " do
      %{option_detail: record} = create_option_detail()
      decision2 = create_decision()

      result = Structure.get_option_detail(record.id, decision2)

      assert result == nil
    end
  end

  describe "create_option_detail/2 " do

    test "creates with valid data" do
      deps = option_detail_deps()
      %{decision: decision} = deps
      attrs = valid_attrs(deps)

      result = Structure.create_option_detail(decision, attrs)

      assert {:ok, %OptionDetail{} = new_record} = result

      assert_equivalent(attrs, new_record)
      assert new_record.decision_id == decision.id
    end

    test "raises without a Decision" do
      assert_raise ArgumentError, ~r/Decision/,
        fn -> Structure.create_option_detail(nil, invalid_attrs()) end
    end

    test "with empty data returns errors" do
      decision = create_decision()

      result = Structure.create_option_detail(decision, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "can't be blank" in errors.title
      refute :input_hint in Map.keys(errors)
      refute :display_hint in Map.keys(errors)
      refute :public in Map.keys(errors)
      refute :sort in Map.keys(errors)
   end

    test "with invalid data returns errors" do
      decision = create_decision()

      attrs = invalid_attrs()
      result = Structure.create_option_detail(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "must include at least one word" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.format
      assert "is invalid" in errors.public
      assert "is invalid" in errors.sort
      assert [_, _, _, _, _] = Map.keys(errors)
    end

    test "a duplicate title with no slug defined generates variant slug" do
      %{option_detail: existing, decision: decision} = deps = create_option_detail()

      attrs = deps |> valid_attrs() |> Map.put(:title, existing.title) |> Map.drop([:slug])
      result = Structure.create_option_detail(decision, attrs)

      assert {:ok, %OptionDetail{} = new_record} = result

      refute existing.slug == new_record.slug
    end

    test "a duplicate slug returns errors" do
      %{option_detail: existing, decision: decision} = deps = create_option_detail()
      attrs = deps |> valid_attrs() |> Map.put(:slug, existing.slug)

      result = Structure.create_option_detail(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "update_option_detail/2" do
    test "updates with valid data" do
      %{option_detail: existing} = deps = create_option_detail()
      attrs = valid_attrs(deps)

      result = Structure.update_option_detail(existing, attrs)

      assert {:ok, %OptionDetail{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "empty data returns errors" do
      %{option_detail: existing} = create_option_detail()

      result = Structure.update_option_detail(existing, empty_attrs())

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "can't be blank" in errors.title
      refute :public in Map.keys(errors)
      refute :sort in Map.keys(errors)
      assert "must have numbers and/or letters" in errors.slug
    end

    test "invalid data returns errors" do
      %{option_detail: existing} = create_option_detail()

      attrs = invalid_attrs()
      result = Structure.update_option_detail(existing, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "must include at least one word" in errors.title
      assert "must have numbers and/or letters" in errors.slug
      assert "is invalid" in errors.format
      assert "is invalid" in errors.sort
      assert "is invalid" in errors.public
      assert [_, _, _, _, _] = Map.keys(errors)
    end

    test "Decision update ignored" do
      %{option_detail: existing} = create_option_detail()
      decision2 = create_decision()

      attrs = %{public: true, decision: decision2}
      result = Structure.update_option_detail(existing, attrs)

      assert {:ok, updated} = result
      assert updated.public == attrs.public
      refute updated.decision.id == decision2.id
      assert updated.decision.id == existing.decision_id
    end

    test "a duplicate title with no slug defined does not update slug" do
      %{option_detail: first, decision: decision} = create_option_detail()
      %{option_detail: second} = deps = create_option_detail(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, first.title) |> Map.drop([:slug])
      result = Structure.update_option_detail(second, attrs)

      assert {:ok, %OptionDetail{} = updated} = result

      assert second.slug == updated.slug
    end

    test "a duplicate title with nil slug defined generates variant slug" do
      %{option_detail: first, decision: decision} = create_option_detail()
      %{option_detail: second} = deps = create_option_detail(decision)

      attrs = deps |> valid_attrs() |> Map.put(:title, first.title) |> Map.put(:slug, nil)
      result = Structure.update_option_detail(second, attrs)

      assert {:ok, %OptionDetail{} = updated} = result
      refute second.slug == updated.slug
      refute second.slug == first.slug
    end

    test "a duplicate slug returns errors" do
      %{option_detail: first, decision: decision} = create_option_detail()
      %{option_detail: second} = deps = create_option_detail(decision)

      attrs = deps |> valid_attrs() |> Map.put(:slug, first.slug)
      result = Structure.update_option_detail(second, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = errors_on(changeset)
      assert "has already been taken" in errors.slug
    end
  end

  describe "delete_option_detail/2" do

    test "deletes" do
      %{option_detail: existing, decision: decision} = create_option_detail()
      to_delete = %OptionDetail{id: existing.id}

      result = Structure.delete_option_detail(to_delete, decision.id)
      assert {:ok, %OptionDetail{}} = result
      assert nil == Repo.get(OptionDetail, existing.id)
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
