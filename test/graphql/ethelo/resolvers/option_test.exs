defmodule GraphQL.EtheloApi.Resolvers.OptionTest do
  @moduledoc """
  Validations and basic access for "Option" resolver, used to load option records
  through graphql.
  Note: Functionality is provided through the OptionResolver.Option context, so these tests
  will cover a limited amount of cases. For details about edge cases or
  specifics of error messages, please refer to `EtheloApi.Structure.OptionTest`

  """
  use EtheloApi.DataCase
  @moduletag option: true, graphql: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.OptionHelper

  alias Kronky.ValidationMessage
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Option
  alias GraphQL.EtheloApi.Resolvers.Option, as: OptionResolver
  describe "list/2" do

    test "returns records matching a Decision" do
      %{option: first, decision: decision} = create_option()
      %{option: second} = create_option(decision)

      parent = %{decision: decision}
      args = %{}
      result = OptionResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%Option{}, %Option{}] = result
      assert_result_ids_match([first, second], result)
    end

    test "filters by Option.id" do
      %{option: matching, decision: decision} = create_option()
      create_option(decision)

      parent = %{decision: decision}
      args = %{id: matching.id}
      result = OptionResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%Option{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by Option.slug" do
      %{option: matching, decision: decision} = create_option()
      create_option(decision)

      parent = %{decision: decision}
      args = %{slug: matching.slug}
      result = OptionResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%Option{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by Option.enabled" do
      decision = create_decision()
      %{option: matching} = create_option(decision, %{enabled: true})
      create_option(decision, %{enabled: false})

      parent = %{decision: decision}
      args = %{enabled: matching.enabled}
      result = OptionResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%Option{}] = result
      assert_result_ids_match([matching], result)
    end

    test "filters by Option.option_category_id" do
      %{option: matching, decision: decision} = create_option()
      create_option(decision)

      parent = %{decision: decision}
      args = %{option_category_id: matching.option_category_id}
      result = OptionResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%Option{}] = result
      assert_result_ids_match([matching], result)
    end

    test "no Option matches" do
      decision = create_decision()

      parent = %{decision: decision}
      args = %{}
      result = OptionResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [] = result
    end
  end

  describe "create/2" do
    test "creates with valid data" do
      deps = option_deps()
      %{decision: decision} = deps

      attrs = deps |> valid_attrs()
      result = OptionResolver.create(decision, attrs)

      assert {:ok, %Option{} = new_record} = result
      assert_equivalent(attrs, new_record)
    end

    test "returns a changeset with invalid data" do
      deps = option_deps()
      %{decision: decision} = deps

      attrs = %{decision: decision}  |> invalid_attrs()
      result = OptionResolver.create(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = changeset |> errors_on() |> Map.keys()
      assert :title in errors
      assert :slug in errors
      assert :sort in errors
      assert :enabled in errors
      assert :option_category_id in errors
      refute :info in errors
      assert [_, _, _, _, _] = errors
    end
  end

  describe "update/2" do

    test "updates with valid data" do
      deps = create_option()
      %{decision: decision} = deps

      attrs = deps |> valid_attrs()
      result = OptionResolver.update(decision, attrs)

      assert {:ok, %Option{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "returns errors when Option does not exist" do
      deps = create_option()
      %{option: option, decision: decision} = deps
      delete_option(option.id)

      attrs = deps |> valid_attrs()
      result = OptionResolver.update(decision, attrs)

      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "returns errors when Decision does not match" do
      deps = create_option()
      decision = create_decision()

      attrs = deps |> valid_attrs()
      result = OptionResolver.update(decision, attrs)

      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "returns a changeset with invalid data" do
      deps = create_option()
      %{option_category: option_category, decision: decision} = deps
      delete_option_category(option_category)

      attrs = deps |> invalid_attrs()
      result = OptionResolver.update(decision, attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = result
      errors = changeset |> errors_on() |> Map.keys()
      assert :title in errors
      assert :slug in errors
      assert :sort in errors
      assert :enabled in errors
      assert :option_category_id in errors
      refute :info in errors
      assert [_, _, _, _, _] = errors
    end
  end

  describe "delete/2" do
    test "deletes" do
      %{decision: decision, option: existing} = create_option()

      attrs = %{decision_id: decision.id, id: existing.id}
      result = OptionResolver.delete(decision, attrs)

      assert {:ok, %Option{}} = result
      assert nil == Structure.get_option(existing.id, decision)
    end

    test "delete/2 does not return errors when Option does not exist" do
      %{decision: decision, option: existing} = create_option()
      delete_option(existing.id)

      attrs = %{decision_id: decision.id, id: existing.id}
      result = OptionResolver.delete(decision, attrs)

      assert {:ok, nil} = result
    end
  end
end
