defmodule EtheloApi.Structure.TestHelper.OptionCategoryHelper do
  @moduledoc false

  import EtheloApi.Structure.TestHelper.GenericHelper
  import ExUnit.Assertions

  def empty_attrs() do
    %{slug: nil, title: nil, info: nil, weighting: nil,
    budget_percent: nil, flat_fee: nil, quadratic: nil, vote_on_percent: nil,
    results_title: nil, keywords: nil,
    xor: nil, apply_participant_weights: nil, primary_detail_id: nil,
    scoring_mode: nil, triangle_base: nil, voting_style: nil, sort: nil,
   }
  end

  def invalid_attrs(deps \\ %{}) do
    %{slug: " ", title: "@@@@", info: false, keywords: false, weighting: "max",
    xor: 3, apply_participant_weights: 4, result_title: "@@@@",
    quadratic: 3, vote_on_percent: 7, budget_percent: "x", flat_fee: "y",
    primary_detail_id: 0,  option_category_id: 2000,
    scoring_mode: "foo", triangle_base: "B", voting_style: "foo", sort: false,
   }
   |> add_option_category_id(deps)
   |> add_decision_id(deps)
   |> add_primary_detail_id(deps)
   |> add_default_low_option_id(deps)
   |> add_default_high_option_id(deps)
  end

  def valid_attrs(%{} = deps) do
    %{
      title: "Title", results_title: "Alt Title", slug: "slug", info: "Information provided.",
      keywords: "one, two", weighting: 75, xor: true, apply_participant_weights: true,
      budget_percent: 0.032, flat_fee: 1.4, quadratic: false, vote_on_percent: true,
      scoring_mode: :none, triangle_base: 3, primary_detail_id: nil, sort: 1,
      voting_style: :one, default_low_option_id: nil, default_high_option_id: nil,
    }
    |> add_option_category_id(deps)
    |> add_decision_id(deps)
    |> add_primary_detail_id(deps)
    |> add_default_low_option_id(deps)
    |> add_default_high_option_id(deps)
  end

  def to_graphql_attrs(attrs) do
    attrs = case Map.get(attrs, :scoring_mode) do
      nil -> attrs
      value -> attrs |> Map.put(:scoring_mode, to_enum_value(value))
    end

    case Map.get(attrs, :voting_style) do
      nil -> attrs
      value -> attrs |> Map.put(:voting_style, to_enum_value(value))
    end
  end

  def assert_equivalent(expected, result) do
    assert expected.title == result.title
    assert expected.results_title == result.results_title
    assert_equivalent_slug(expected.slug, result.slug)
    assert expected.info == result.info
    assert expected.keywords == result.keywords
    assert expected.weighting == result.weighting
    assert expected.xor == result.xor
    assert expected.triangle_base == result.triangle_base
    assert expected.scoring_mode == result.scoring_mode
    assert expected.apply_participant_weights == result.apply_participant_weights
    assert expected.voting_style == result.voting_style
    assert expected.sort == result.sort
    assert expected.budget_percent == result.budget_percent
    assert expected.flat_fee == result.flat_fee
    assert expected.vote_on_percent == result.vote_on_percent
    assert expected.quadratic == result.quadratic
  end

  def add_decision_id(attrs, %{decision: decision}), do: Map.put(attrs, :decision_id, decision.id)
  def add_decision_id(attrs, _deps), do: attrs

  def add_option_category_id(attrs, %{option_category: option_category}), do: Map.put(attrs, :id, option_category.id)
  def add_option_category_id(attrs, _deps), do: attrs

  def add_primary_detail_id(attrs, %{primary_detail: primary_detail}), do: Map.put(attrs, :primary_detail_id, primary_detail.id)
  def add_primary_detail_id(attrs, _deps), do: attrs

  def add_default_low_option_id(attrs, %{default_low_option: default_low_option}), do: Map.put(attrs, :default_low_option_id, default_low_option.id)
  def add_default_low_option_id(attrs, _deps), do: attrs

  def add_default_high_option_id(attrs, %{default_high_option: default_high_option}), do: Map.put(attrs, :default_high_option_id, default_high_option.id)
  def add_default_high_option_id(attrs, _deps), do: attrs

end
