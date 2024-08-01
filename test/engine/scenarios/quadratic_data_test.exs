defmodule Engine.Scenarios.QuadraticDataTest do
  @moduledoc """
  Validations and basic access for QuadraticData
  """
  use EtheloApi.DataCase
  alias Engine.Scenarios.QuadraticData
  alias Engine.Invocation.ScoringData
  @moduletag data: true, quad: true

  test "calculates" do
    %{decision: decision, scenario_config: scenario_config} = EtheloApi.Blueprints.QuadVotingProject.build()

    voting_data = ScoringData.initialize_all_voting(decision.id, scenario_config.id)
  
    quad_data = QuadraticData.initialize(voting_data)

    fields = [
      # inherited
      :option_category_range_votes,

      # hard coded
      :user_seeds, :total_available, :cutoff,
      :seed_allocation_percent, :vote_allocation_percent,
      :maximum_allocation, :round_to,

      # match
      :seed_option_detail,

      #calculated
      :seeds_by_option, :seeds_assigned_by_oc, :seeds_assigned_total,
      :seed_allocation_target, :vote_allocation_target,
      :positive_seed_votes_sq_by_oc,  :positive_seed_votes_sq_sum,
      :positive_seed_votes_sum_by_oc, :positive_seed_votes_sum,
      ]

    Enum.map(fields, fn(field) ->
      refute {field, nil} == {field, Map.get(quad_data, field)}
    end)

    assert 18 == Enum.count(quad_data.option_category_range_votes)
    assert 125 == quad_data.user_seeds
    assert 580000 == quad_data.total_available
    assert 7500 == quad_data.cutoff
    assert 0.75 == quad_data.seed_allocation_percent
    assert 0.25 == quad_data.vote_allocation_percent
    assert 50000 == quad_data.maximum_allocation
    assert 5000 == quad_data.round_to

    assert 435000 == quad_data.seed_allocation_target
    assert 145000 == quad_data.vote_allocation_target
    assert "seeds"== quad_data.seed_option_detail.slug

    # option_map = voting_data.options
    #   |> Enum.map(fn(o) -> {String.to_atom(o.slug), o.id} end)
    #   |> Enum.into(%{})
    #
    # expected_sbo = %{ 2 => 1, 3 => 4, 4 => 9, 5 => 16, 6 => 25, 8 => 1, 9 => 4, 10 => 9, 11 => 16, 12 => 25 }
    # assert quad_data.seeds_by_option == expected_sbo

    oc_map = voting_data.option_categories
      |> Enum.map(fn(oc) -> {String.to_atom(oc.slug), oc.id} end)
      |> Enum.into(%{})

    oc1_id = oc_map[:first]
    oc2_id = oc_map[:second]
    oc3_id = oc_map[:third]
    oc4_id = oc_map[:fourth]
    oc5_id = oc_map[:fifth]

    expected_sboc = %{oc1_id => 42, oc2_id => 23, oc3_id => 42, oc4_id => 42, oc5_id => 1}

    assert expected_sboc == quad_data.seeds_assigned_by_oc
    assert 150 == quad_data.seeds_assigned_total

    expected_pvoc = %{ oc1_id => 3, oc2_id => 4, oc3_id => 3, oc4_id => 3, oc5_id => 1}
    assert expected_pvoc == quad_data.positive_seed_votes_sum_by_oc

    expected_pv_sq_oc = %{oc1_id => 9, oc2_id => 16, oc3_id => 9, oc4_id => 9, oc5_id => 1 }
    assert expected_pv_sq_oc == quad_data.positive_seed_votes_sq_by_oc
    assert 44 == quad_data.positive_seed_votes_sq_sum
    assert 14 == quad_data.positive_seed_votes_sum

  end

end
