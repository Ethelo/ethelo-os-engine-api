defmodule EtheloApi.Voting.QuadraticBuilderTest do
  @moduledoc """
  Validations and basic access for QuadraticBuilder
  note: this is called through ScoringData and the necessary setup happens there
  """
  use EtheloApi.DataCase
  alias Engine.Invocation.ScoringData
  @moduletag data: true, quad: true

  test "calculates" do
    %{decision: decision, scenario_config: scenario_config} = EtheloApi.Blueprints.QuadVotingProject.build()

    voting_data = ScoringData.initialize_all_voting(decision.id, scenario_config.id)
      |> ScoringData.add_scenario_import_data()

    quadratic_totals  = voting_data.quadratic_totals
    assert %{global: global, by_oc: by_oc} = quadratic_totals

    global_fields = [:user_seeds, :total_available, :cutoff,
        :seed_allocation_percent, :vote_allocation_percent,
        :maximum_allocation, :round_to,
        :seed_allocation_target, :vote_allocation_target,
        :seed_allocation_total, :vote_allocation_total,
        :combined_allocation_total, :final_allocation_total,
        :seeds_assigned_total, :remaining_after_seed,
        :positive_seed_votes_sum, :positive_seed_votes_sq
      ]

    Enum.map(global_fields, fn(field) ->
      refute {field, nil} == {field, Map.get(global, field)}
    end)

    assert 125 == global.user_seeds
    assert 580000 == global.total_available
    assert 7500 == global.cutoff
    assert 0.75 == global.seed_allocation_percent
    assert 0.25 == global.vote_allocation_percent
    assert 50000 == global.maximum_allocation
    assert 5000 == global.round_to
    assert 435000 == global.seed_allocation_target
    assert 145000 == global.vote_allocation_target
    assert 150 == global.seeds_assigned_total
    assert 44 == global.positive_seed_votes_sq
    assert 14 == global.positive_seed_votes_sum

    assert 5 == Enum.count(by_oc)

    oc_map = voting_data.option_categories
      |> Enum.map(fn(oc) -> {String.to_atom(oc.slug), oc.id} end)
      |> Enum.into(%{})

    oc1_id = oc_map[:first]
    oc2_id = oc_map[:second]
    _oc3_id = oc_map[:third]
    _oc4_id = oc_map[:fourth]
    oc5_id = oc_map[:fifth]

    expected1 = %{
      seed_allocation: 121800, vote_allocation: 29659, combined_allocation: 151459,
      final_allocation: 50000, positive_seed_votes_sum: 3, positive_seed_votes_sq: 9, seeds_assigned: 42,
    }

    assert by_oc[oc1_id] == expected1

    expected2 = %{
      seed_allocation: 66700, vote_allocation: 52727, combined_allocation: 119427,
      final_allocation: 50000, positive_seed_votes_sum: 4, positive_seed_votes_sq: 16, seeds_assigned: 23,
    }

    assert by_oc[oc2_id] == expected2

    expected5 = %{
      seed_allocation: 2900, vote_allocation: 3295, combined_allocation: 6195,
      final_allocation: 0, positive_seed_votes_sum: 1, positive_seed_votes_sq: 1, seeds_assigned: 1,
    }

    assert by_oc[oc5_id] == expected5

    assert 435000 == global.seed_allocation_total
    assert 144999 == global.vote_allocation_total
    assert 579999 == global.combined_allocation_total
    assert 200000 == global.final_allocation_total
    # duplicated to match scenario set field names
    assert 435000 == global.seed_allocation
    assert 144999 == global.vote_allocation_total
    assert 579999 == global.combined_allocation
    assert 200000 == global.final_allocation

  end

end
