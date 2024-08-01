defmodule EtheloApi.Structure.TestHelper.CriterionHelper do
  @moduledoc false

  import EtheloApi.Structure.TestHelper.GenericHelper
  import ExUnit.Assertions

  def empty_attrs() do
    %{title: nil, slug: nil, info: nil, weighting: nil, bins: nil, sort: nil,
      support_only: nil, apply_participant_weights: nil}
  end

  def invalid_attrs(%{} = deps \\ %{}) do
    %{slug: " ", title: "@@@", info: false, weighting: 10000, bins: "three",
    support_only: 3, apply_participant_weights: 4, sort: false }
    |> add_decision_id(deps)
    |> add_criteria_id(deps)
  end

  def valid_attrs(%{} = deps \\ %{}) do
    %{title: "Title", slug: "slug",
      info: "Information provided.",
      weighting: 75, bins: 5, support_only: true,
      apply_participant_weights: true, sort: 1,
    }
    |> add_decision_id(deps)
    |> add_criteria_id(deps)
  end

  def assert_equivalent(expected, result) do
    assert expected.title == result.title
    assert_equivalent_slug(expected.slug, result.slug)
    assert expected.info == result.info
    assert expected.support_only == result.support_only
    assert expected.apply_participant_weights == result.apply_participant_weights
    assert expected.bins == result.bins
    assert expected.weighting == result.weighting
    assert expected.sort == result.sort
  end

  def to_graphql_attrs(attrs) do
    attrs
  end

  def add_decision_id(attrs, %{decision: decision}), do: Map.put(attrs, :decision_id, decision.id)
  def add_decision_id(attrs, _deps), do: attrs

  def add_criteria_id(attrs, %{criteria: criteria}), do: Map.put(attrs, :id, criteria.id)
  def add_criteria_id(attrs, _deps), do: attrs

end
