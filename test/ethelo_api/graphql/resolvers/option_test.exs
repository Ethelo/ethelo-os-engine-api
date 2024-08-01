defmodule EtheloApi.Graphql.Resolvers.OptionTest do
  @moduledoc """
  Validations and basic access for Option resolver
  through graphql.
  Note: Functionality is provided through the OptionResolver.Option context, so these tests
  will cover a limited amount of cases. For details about edge cases or
  specifics of error messages, please refer to `EtheloApi.Structure.OptionTest`

  """
  use EtheloApi.DataCase
  @moduletag option: true, graphql: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.OptionHelper

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Option
  alias EtheloApi.Graphql.Resolvers.Option, as: OptionResolver

  def test_list_filtering(field_name) do
    %{option: to_match, decision: decision} = create_option()
    %{option: _excluded} = create_option(decision)
    test_list_filtering(field_name, to_match, decision)
  end

  def test_list_filtering(field_name, to_match, decision) do
    parent = %{decision: decision}
    args = %{} |> Map.put(field_name, Map.get(to_match, field_name))
    result = OptionResolver.list(parent, args, nil)

    assert {:ok, result} = result
    assert [%Option{}] = result
    assert_result_ids_match([to_match], result)
  end

  describe "list/2" do
    test "filters by decision_id" do
      %{option: to_match1, decision: decision} = create_option()
      %{option: to_match2} = create_option(decision)
      %{option: _excluded} = create_option()

      parent = %{decision: decision}
      args = %{}
      result = OptionResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%Option{}, %Option{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
    end

    test "filters by id" do
      test_list_filtering(:id)
    end

    test "filters by slug" do
      test_list_filtering(:slug)
    end

    test "filters by option_category_id" do
      test_list_filtering(:option_category_id)
    end

    test "filters by enabled" do
      decision = create_decision()
      %{option: to_match} = create_option(decision, %{enabled: true})
      %{option: _excluded} = create_option(decision, %{enabled: false})
      test_list_filtering(:enabled, to_match, decision)
    end

    test "no matching records" do
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
      %{decision: decision} = deps = option_deps()

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = OptionResolver.create(params, nil)
      assert {:ok, %Option{} = new_record} = result
      assert_equivalent(attrs, new_record)
    end

    test "invalid data returns changeset" do
      decision = create_decision()

      attrs = %{decision: decision} |> invalid_attrs()

      params = to_graphql_input_params(attrs, decision)
      result = OptionResolver.create(params, nil)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> error_map()
      expected = [:title, :slug, :enabled, :sort]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end
  end

  describe "update/2" do
    test "updates with valid data" do
      %{decision: decision} = deps = create_option()

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = OptionResolver.update(params, nil)
      assert {:ok, %Option{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "invalid Option returns error" do
      %{decision: decision, option: to_delete} = deps = create_option()
      delete_option(to_delete.id)

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = OptionResolver.update(params, nil)
      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "Decision mismatch returns changeset" do
      deps = create_option()
      decision = create_decision()
      deps = Map.put(deps, :decision, decision)

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = OptionResolver.update(params, nil)
      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "invalid data returns changeset" do
      %{decision: decision} = deps = create_option()
      %{option_category: option_category} = create_option_category()

      attrs =
        deps
        |> invalid_attrs()
        |> Map.put(:option_category_id, option_category.id)

      params = to_graphql_input_params(attrs, decision)
      result = OptionResolver.update(params, nil)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> error_map()
      expected = [:title, :slug, :enabled, :sort, :option_category_id]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end
  end

  describe "delete/2" do
    test "deletes" do
      %{option: to_delete, decision: decision} = create_option()

      attrs = %{decision_id: decision.id, id: to_delete.id}
      params = to_graphql_input_params(attrs, decision)
      result = OptionResolver.delete(params, nil)

      assert {:ok, %Option{}} = result
      assert nil == Structure.get_option(to_delete.id, decision)
    end

    test "when record does not exist return successful nil" do
      %{decision: decision, option: to_delete} = create_option()
      delete_option(to_delete.id)

      attrs = %{decision_id: decision.id, id: to_delete.id}
      params = to_graphql_input_params(attrs, decision)
      result = OptionResolver.delete(params, nil)

      assert {:ok, nil} = result
    end
  end
end
