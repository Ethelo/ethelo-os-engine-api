defmodule EtheloApi.Graphql.Resolvers.OptionDetailTest do
  @moduledoc """
  Validations and basic access for OptionDetail resolver
  through graphql.
  Note: Functionality is provided through the OptionDetailResolver.OptionDetail context, so these tests
  will cover a limited amount of cases. For details about edge cases or
  specifics of error messages, please refer to `EtheloApi.Structure.OptionDetailTest`

  """
  use EtheloApi.DataCase
  @moduletag option_detail: true, graphql: true

  import EtheloApi.Structure.Factory
  import EtheloApi.Structure.TestHelper.OptionDetailHelper

  alias EtheloApi.Structure
  alias EtheloApi.Structure.OptionDetail
  alias EtheloApi.Graphql.Resolvers.OptionDetail, as: OptionDetailResolver

  def test_list_filtering(field_name) do
    %{option_detail: to_match, decision: decision} = create_option_detail()
    %{option_detail: _excluded} = create_option_detail(decision)

    parent = %{decision: decision}
    args = %{} |> Map.put(field_name, Map.get(to_match, field_name))
    result = OptionDetailResolver.list(parent, args, nil)

    assert {:ok, result} = result
    assert [%OptionDetail{}] = result
    assert_result_ids_match([to_match], result)
  end

  describe "list/2" do
    test "filters by decision_id" do
      %{option_detail: to_match1, decision: decision} = create_option_detail()
      %{option_detail: to_match2} = create_option_detail(decision)
      %{option_detail: _excluded} = create_option_detail()

      parent = %{decision: decision}
      args = %{}
      result = OptionDetailResolver.list(parent, args, nil)

      assert {:ok, result} = result
      assert [%OptionDetail{}, %OptionDetail{}] = result
      assert_result_ids_match([to_match1, to_match2], result)
    end

    test "filters by id" do
      test_list_filtering(:id)
    end

    test "filters by slug" do
      test_list_filtering(:slug)
    end

    test "no matching records" do
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
      %{decision: decision} = deps = option_detail_deps()

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = OptionDetailResolver.create(params, nil)
      assert {:ok, %OptionDetail{} = new_record} = result
      assert_equivalent(attrs, new_record)
    end

    test "invalid data returns changeset" do
      %{decision: decision} = deps = option_detail_deps()

      attrs = invalid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = OptionDetailResolver.create(params, nil)
      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> error_map()

      expected = [:title, :slug, :format, :public, :sort]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end
  end

  describe "update/2" do
    test "updates with valid data" do
      %{decision: decision} = deps = create_option_detail()

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = OptionDetailResolver.update(params, nil)
      assert {:ok, %OptionDetail{} = updated} = result
      assert_equivalent(attrs, updated)
    end

    test "invalid OptionDetail returns error" do
      %{decision: decision, option_detail: to_delete} = deps = create_option_detail()
      delete_option_detail(to_delete.id)

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = OptionDetailResolver.update(params, nil)
      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "Decision mismatch returns changeset" do
      deps = create_option_detail()
      decision = create_decision()
      deps = Map.put(deps, :decision, decision)

      attrs = valid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)

      result = OptionDetailResolver.update(params, nil)
      assert {:ok, %ValidationMessage{} = message} = result
      assert %{code: :not_found, field: :id} = message
    end

    test "invalid data returns changeset" do
      %{decision: decision} = deps = create_option_detail()

      attrs = invalid_attrs(deps)
      params = to_graphql_input_params(attrs, decision)
      result = OptionDetailResolver.update(params, nil)

      assert {:error, %Changeset{} = changeset} = result
      errors = changeset |> error_map()

      expected = [:title, :slug, :format, :public, :sort]
      assert {[], []} = error_diff(expected, Map.keys(errors))
    end
  end

  describe "delete/2" do
    test "deletes" do
      %{decision: decision, option_detail: to_delete} = create_option_detail()

      attrs = %{decision_id: decision.id, id: to_delete.id}
      params = to_graphql_input_params(attrs, decision)
      result = OptionDetailResolver.delete(params, nil)

      assert {:ok, %OptionDetail{}} = result
      assert nil == Structure.get_option_detail(to_delete.id, decision)
    end

    test "when record does not exist return successful nil" do
      %{decision: decision, option_detail: to_delete} = create_option_detail()
      delete_option_detail(to_delete.id)

      attrs = %{decision_id: decision.id, id: to_delete.id}
      params = to_graphql_input_params(attrs, decision)
      result = OptionDetailResolver.delete(params, nil)

      assert {:ok, nil} = result
    end
  end
end
