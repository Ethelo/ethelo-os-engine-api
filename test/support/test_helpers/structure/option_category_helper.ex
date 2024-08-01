defmodule EtheloApi.Structure.TestHelper.OptionCategoryHelper do
  @moduledoc """
  OptionCategory specific test tools
  """
  import EtheloApi.TestHelper.GenericHelper
  import ExUnit.Assertions

  def fields() do
    %{
      apply_participant_weights: :boolean,
      budget_percent: :float,
      default_high_option_id: :string,
      default_low_option_id: :string,
      flat_fee: :float,
      id: :string,
      info: :string,
      inserted_at: :date,
      keywords: :string,
      primary_detail_id: :string,
      quadratic: :boolean,
      results_title: :string,
      scoring_mode: :enum,
      slug: :string,
      sort: :integer,
      title: :string,
      triangle_base: :integer,
      updated_at: :date,
      vote_on_percent: :boolean,
      voting_style: :enum,
      weighting: :integer,
      xor: :boolean
    }
  end

  def fields(only) do
    Map.take(fields(), only)
  end

  def input_field_names() do
    [
      :apply_participant_weights,
      :budget_percent,
      :default_high_option_id,
      :default_low_option_id,
      :flat_fee,
      :info,
      :keywords,
      :primary_detail_id,
      :quadratic,
      :results_title,
      :scoring_mode,
      :slug,
      :sort,
      :title,
      :triangle_base,
      :vote_on_percent,
      :voting_style,
      :weighting,
      :xor
    ]
  end

  def empty_attrs() do
    %{
      apply_participant_weights: nil,
      budget_percent: nil,
      flat_fee: nil,
      high_option_id: nil,
      info: nil,
      keywords: nil,
      low_option_id: nil,
      primary_detail_id: nil,
      quadratic: nil,
      results_title: nil,
      scoring_mode: nil,
      slug: nil,
      sort: nil,
      title: nil,
      triangle_base: nil,
      vote_on_percent: nil,
      voting_style: nil,
      weighting: nil,
      xor: nil
    }
  end

  def invalid_attrs(deps \\ %{}) do
    %{
      apply_participant_weights: 4,
      budget_percent: "x",
      flat_fee: "y",
      info: false,
      keywords: false,
      option_category_id: 2000,
      primary_detail_id: 0,
      quadratic: 3,
      results_title: "@@@@",
      scoring_mode: "foo",
      slug: "@@@",
      sort: false,
      title: " ",
      triangle_base: "B",
      vote_on_percent: 7,
      voting_style: "foo",
      weighting: "max",
      xor: 3
    }
    |> add_record_id(deps)
    |> add_decision_id(deps)
    |> add_primary_detail_id(deps)
    |> add_default_low_option_id(deps)
    |> add_default_high_option_id(deps)
  end

  def valid_attrs(deps \\ %{}) do
    %{
      apply_participant_weights: true,
      budget_percent: 0.032,
      default_high_option_id: nil,
      default_low_option_id: nil,
      flat_fee: 1.4,
      info: "Information provided.",
      keywords: "one, two",
      primary_detail_id: nil,
      quadratic: false,
      results_title: "Alt Title",
      scoring_mode: :none,
      slug: "slug",
      sort: 1,
      title: "Title",
      triangle_base: 3,
      vote_on_percent: true,
      voting_style: :one,
      weighting: 75,
      xor: true
    }
    |> add_record_id(deps)
    |> add_decision_id(deps)
    |> add_primary_detail_id(deps)
    |> add_default_low_option_id(deps)
    |> add_default_high_option_id(deps)
  end

  def assert_equivalent(expected, result) do
    assert expected.apply_participant_weights == result.apply_participant_weights
    assert expected.budget_percent == result.budget_percent
    assert expected.flat_fee == result.flat_fee
    assert expected.info == result.info
    assert expected.keywords == result.keywords
    assert expected.quadratic == result.quadratic
    assert expected.results_title == result.results_title
    assert expected.scoring_mode == result.scoring_mode
    assert_equivalent_slug(expected.slug, result.slug)
    assert expected.sort == result.sort
    assert expected.title == result.title
    assert expected.triangle_base == result.triangle_base
    assert expected.vote_on_percent == result.vote_on_percent
    assert expected.voting_style == result.voting_style
    assert expected.weighting == result.weighting
    assert expected.xor == result.xor
  end

  def add_primary_detail_id(attrs, %{primary_detail: primary_detail}),
    do: Map.put(attrs, :primary_detail_id, primary_detail.id)

  def add_primary_detail_id(attrs, _deps), do: attrs

  def add_default_low_option_id(attrs, %{default_low_option: default_low_option}),
    do: Map.put(attrs, :default_low_option_id, default_low_option.id)

  def add_default_low_option_id(attrs, _deps), do: attrs

  def add_default_high_option_id(attrs, %{default_high_option: default_high_option}),
    do: Map.put(attrs, :default_high_option_id, default_high_option.id)

  def add_default_high_option_id(attrs, _deps), do: attrs

  def add_record_id(attrs, %{option_category: option_category}),
    do: Map.put(attrs, :id, option_category.id)

  def add_record_id(attrs, _deps), do: attrs
end
