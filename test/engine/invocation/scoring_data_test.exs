defmodule Engine.Invocation.ScoringDataTest do
  @moduledoc """
  Validations and basic access for ScoringData
  """
  use EtheloApi.DataCase
  alias Engine.Invocation.ScoringData
  @moduletag data: true

  setup do
    EtheloApi.Blueprints.PizzaProject.build()
  end

  def refute_nil_fields(data, fields) do
    Enum.map(fields, fn field ->
      refute {nil, field} == {Map.get(data, field), field}
    end)
  end

  def refute_common_nil_fields(data) do
    fields = [
      :criterias,
      :criterias_by_slug,
      :decision,
      :option_categories,
      :option_categories_by_id,
      :option_categories_by_slug,
      :options,
      :options_by_slug,
      :options_by_oc,
      :option_details,
      :option_detail_values,
    ]
    refute_nil_fields(data, fields)
  end

  def assert_common_values(data) do
    assert Enum.count(data.criterias) == 2
    assert Enum.count(data.criterias_by_slug) == 2
    assert Enum.count(data.option_categories) == 5
    assert Enum.count(data.option_categories_by_id) == 5
    assert Enum.count(data.option_categories_by_slug) == 5
    assert Enum.count(data.options) == 7
    assert Enum.count(data.options_by_slug) == 7
    assert Enum.count(data.options_by_oc) == 3
    assert Enum.count(data.option_details) == 5
    assert Enum.count(data.option_detail_values) == 25
  end

  test "decision_json_data filled in", context do
    %{decision: decision} = context
    data = ScoringData.initialize_decision_json_data(decision.id)

    refute_common_nil_fields(data)
    assert_common_values(data)

    fields = [
      :auto_constraints,
      :calculations,
      :constraints,
      :option_ids_by_filter_id,
      :option_ids_by_filter_slug,
      :option_filters,
      :variables,
      ]

    refute_nil_fields(data, fields)

    assert Enum.count(data.calculations) == 3
    assert Enum.count(data.constraints) == 6
    assert Enum.count(data.auto_constraints) == 1
    assert Enum.count(data.option_filters) == 10
    assert Enum.count(data.option_ids_by_filter_id) == 10
    assert Enum.count(data.option_ids_by_filter_slug) == 10
    assert Enum.count(data.variables) == 14
  end

  test "all voting values filled in", context do
    %{decision: decision, scenario_config: scenario_config} = context
    data = ScoringData.initialize_all_voting(decision, scenario_config)

    refute_common_nil_fields(data)
    assert_common_values(data)

    fields = [
      :bin_votes,
      :option_category_range_votes,
      :option_category_weights,
      :criteria_weights,
      :participants,
      :scenario_config,
    ]

    refute_nil_fields(data, fields)

    assert Enum.count(data.participants) == 2
    assert Enum.count(data.bin_votes) > 10
    assert Enum.count(data.option_category_range_votes) == 2
    assert Enum.count(data.option_category_weights) == 2
    assert Enum.count(data.criteria_weights) == 2
  end


  test "filters to one participant's votes", context do
    %{decision: decision, participants: participants, scenario_config: scenario_config} = context

    participant = participants[:one]

    data = ScoringData.initialize_single_voting(decision, participant.id, scenario_config.id)

    refute_common_nil_fields(data)
    assert_common_values(data)

    fields = [
      :bin_votes,
      :option_category_range_votes,
      :option_category_weights,
      :criteria_weights,
      :participants,
      :scenario_config,
    ]

    refute_nil_fields(data, fields)

    bin_votes = data.bin_votes
    option_category_range_votes = data.option_category_range_votes
    option_category_weights = data.option_category_weights
    criteria_weights = data.criteria_weights

    assert [_] = data.participants
    assert Enum.count(bin_votes) == 10
    assert Enum.count(option_category_range_votes) == 1
    assert Enum.count(option_category_weights) == 1
    assert Enum.count(criteria_weights) == 1
  end

  test "filters nonexistant participant from votes", context do
    %{decision: decision} = context
    invalid_id = 2900
    data = ScoringData.initialize_single_voting(decision, invalid_id)

    assert [] = data.participants
    assert [] = data.bin_votes
    assert [] = data.option_category_range_votes
    assert [] = data.option_category_weights
    assert [] = data.criteria_weights
  end

  test "scenario import data added", context do
    %{decision: decision, scenario_config: scenario_config} = context
    data = decision
        |> ScoringData.initialize_all_voting(scenario_config)
        |> ScoringData.add_scenario_import_data()

      #  IO.inspect(ScoringData.add_decision_json_data(data, true, true), printable_limit: :infinity)


    fields = [
      :bin_votes_by_option,
      :calculations,
      :calculations_by_slug,
      :constraints,
      :constraints_by_slug,
      :criteria_weights_by_criteria,
      :option_category_weights_by_oc,
      :option_category_range_votes_by_oc,
      ]

    refute_nil_fields(data, fields)

    assert Enum.count(data.bin_votes_by_option) == 5
    assert Enum.count(data.calculations) == 3
    assert Enum.count(data.calculations_by_slug) == 3
    assert Enum.count(data.constraints_by_slug) == 6
    assert Enum.count(data.criteria_weights_by_criteria) == 1
    assert Enum.count(data.option_category_weights_by_oc) == 1
    assert Enum.count(data.option_category_range_votes_by_oc) == 1
  end
  #
  # test "creates vote dump" do
  #   %{decision: decision} = EtheloApi.Blueprints.PizzaProject.build(false)
  #   voting_dump = ScoringData.vote_data_dump(decision.id)
  #
  #   bin_votes = voting_dump.bin_votes
  #   option_category_range_votes = voting_dump.option_category_range_votes
  #   option_category_weights = voting_dump.option_category_weights
  #   criteria_weights = voting_dump.criteria_weights
  #
  #   assert {} = bin_votes |> hd
  #   #todo - better test, check that participant ids are changed
  #   assert Enum.count(bin_votes) > 10
  #   assert Enum.count(option_category_range_votes) > 1
  #   assert Enum.count(option_category_weights) > 2
  #   assert Enum.count(criteria_weights) > 2
  #
  # end
end
