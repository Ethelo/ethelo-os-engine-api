defmodule GraphQL.EtheloApi.Resolvers.OptionDetailTest do
  @moduledoc """
  Validations and basic access for "OptionDetail" resolver, used to load option_detail records
  through graphql.
  Note: Functionality is provided through the OptionDetailResolver.OptionDetail context, so these tests
  will cover a limited amount of cases. For details about edge cases or
  specifics of error messages, please refer to `EtheloApi.Structure.OptionDetailTest`

  """
  use EtheloApi.DataCase
  @moduletag option_detail: true, graphql: true

  import EtheloApi.Structure.Factory
  alias Kronky.ValidationMessage
  alias EtheloApi.Structure
  alias EtheloApi.Structure.OptionDetail
  alias Ecto.Changeset
  alias GraphQL.EtheloApi.Resolvers.OptionDetail, as: OptionDetailResolver

  def valid_attrs(decision) do
     %{
       slug: "slug", title: "Title",
       display_hint: "Display",
       format: :float, public: true, input_hint: "input",
       decision_id: decision.id,
     }
  end

   def valid_attrs(decision, option_detail) do
     decision |> valid_attrs() |> Map.put(:id, option_detail.id)
  end

  def invalid_attrs(decision) do
     %{
       slug: "  ", title: "@@@", format: "two", public: 3, input_hint: "seven",
       decision_id: decision.id,
     }
  end

   def invalid_attrs(decision, option_detail) do
     decision |> invalid_attrs() |> Map.put(:id, option_detail.id)
  end

  def assert_equivalent(expected, result) do
    assert expected.title == result.title
    assert_equivalent_slug(expected.slug, result.slug)
    assert expected.format == result.format
    assert expected.public == result.public
    assert expected.display_hint == result.display_hint
    assert expected.input_hint == result.input_hint
  end

  describe "list/2" do
    test "returns all OptionDetails for a Decision" do
      %{option_detail: first, decision: decision} = create_option_detail()
      %{option_detail: second} = create_option_detail(decision)

      parent = %{decision: decision}
      args = %{}
      result = OptionDetailResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%OptionDetail{}, %OptionDetail{}] = result
      assert_result_ids_match([first, second], result)
    end

    test "filters by OptionDetail.id" do
      %{option_detail: first, decision: decision} = create_option_detail()
      create_option_detail(decision)

      parent = %{decision: decision}
      args = %{id: first.id}
      result = OptionDetailResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%OptionDetail{}] = result
      assert_result_ids_match([first], result)
    end

    test "filters by OptionDetail.slug" do
      %{option_detail: first, decision: decision} = create_option_detail()
      create_option_detail(decision)

      parent = %{decision: decision}
      args = %{slug: first.slug}
      result = OptionDetailResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%OptionDetail{}] = result
      assert_result_ids_match([first], result)
    end

    test "no OptionDetail matches" do
      decision = create_decision()

      parent = %{decision: decision}
      args = %{}
      result = OptionDetailResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [] = result
    end
  end

  describe "create/2" do
    test "creates with valid data" do
      %{decision: decision} = option_detail_deps()

      attrs = valid_attrs(decision)
      result = OptionDetailResolver.create(decision, attrs)

      assert {:ok, %OptionDetail{} = new_record} = result
      assert_equivalent(attrs, new_record)
    end

    test "returns a  with invalid data" do
       %{decision: decision} = option_detail_deps()

      attrs = invalid_attrs(decision)
      result = OptionDetailResolver.create(decision, attrs)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> errors_on() |> Map.keys()
      assert :title in errors
      assert :slug in errors
      assert :public in errors
      assert :format in errors
      refute :input_hint in errors
      assert [_, _, _, _] = errors
    end
  end

  describe "update/2" do

    test "updates with valid data" do
      %{decision: decision, option_detail: existing} = create_option_detail()

      attrs = valid_attrs(decision, existing)

      result = OptionDetailResolver.update(decision, attrs)
      assert {:ok, %OptionDetail{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "returns errors when OptionDetail does not exist" do
      %{decision: decision, option_detail: existing} = create_option_detail()
      delete_option_detail(existing.id)

      attrs = valid_attrs(decision, existing)
      result = OptionDetailResolver.update(decision, attrs)

      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "returns errors when Decision does not match" do
      %{option_detail: existing} = create_option_detail()
      decision = create_decision()

      attrs = valid_attrs(decision, existing)
      result = OptionDetailResolver.update(decision, attrs)

      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "returns a changeset with invalid data" do
      %{decision: decision, option_detail: existing} = create_option_detail()

      attrs = invalid_attrs(decision, existing)
      result = OptionDetailResolver.update(decision, attrs)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> errors_on() |> Map.keys()
      assert :title in errors
      assert :slug in errors
      assert :public in errors
      assert :format in errors
      refute :input_hint in errors
      assert [_, _, _, _] = errors
    end
  end

  describe "delete/2" do
    test "deletes" do
      %{decision: decision, option_detail: existing} = create_option_detail()

      attrs = %{decision_id: decision.id, id: existing.id}
      result = OptionDetailResolver.delete(decision, attrs)

      assert {:ok, %OptionDetail{}} = result
      assert nil == Structure.get_option_detail(existing.id, decision)
    end

    test "delete/2 silently fails when OptionDetail does not exist" do
      %{decision: decision, option_detail: existing} = create_option_detail()
      delete_option_detail(existing.id)

      attrs = %{decision_id: decision.id, id: existing.id}
      result = OptionDetailResolver.delete(decision, attrs)

      assert {:ok, nil} = result
    end
  end
end
