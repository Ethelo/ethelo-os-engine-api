defmodule EtheloApi.Structure.TestHelper.CriteriaHelper do
  @moduledoc """
  Criteria specific test tools
  """

  import EtheloApi.TestHelper.GenericHelper
  import ExUnit.Assertions

  def fields() do
    %{
      apply_participant_weights: :boolean,
      bins: :integer,
      id: :string,
      info: :string,
      inserted_at: :date,
      slug: :string,
      sort: :integer,
      support_only: :boolean,
      title: :string,
      updated_at: :date,
      weighting: :integer
    }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  def input_field_names() do
    [
      :apply_participant_weights,
      :bins,
      :info,
      :slug,
      :sort,
      :support_only,
      :title,
      :weighting
    ]
  end

  def empty_attrs() do
    %{
      apply_participant_weights: nil,
      bins: nil,
      info: nil,
      slug: nil,
      sort: nil,
      support_only: nil,
      title: nil,
      weighting: nil
    }
  end

  def invalid_attrs(%{} = deps \\ %{}) do
    %{
      apply_participant_weights: 4,
      bins: "three",
      info: false,
      slug: "@@@",
      sort: false,
      support_only: 3,
      title: "",
      weighting: 10_000
    }
    |> add_decision_id(deps)
    |> add_record_id(deps)
  end

  def valid_attrs(%{} = deps \\ %{}) do
    %{
      apply_participant_weights: true,
      bins: 5,
      info: "Information provided.",
      slug: "slug",
      sort: 1,
      support_only: true,
      title: "Title",
      weighting: 75
    }
    |> add_decision_id(deps)
    |> add_record_id(deps)
  end

  def assert_equivalent(expected, result) do
    assert expected.apply_participant_weights == result.apply_participant_weights
    assert expected.bins == result.bins
    assert expected.info == result.info
    assert_equivalent_slug(expected.slug, result.slug)
    assert expected.sort == result.sort
    assert expected.support_only == result.support_only
    assert expected.title == result.title
    assert expected.weighting == result.weighting
  end

  def add_record_id(attrs, %{criteria: criteria}), do: Map.put(attrs, :id, criteria.id)
  def add_record_id(attrs, _deps), do: attrs
end
