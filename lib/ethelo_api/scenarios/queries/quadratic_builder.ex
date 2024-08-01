defmodule EtheloApi.Scenarios.QuadraticBuilder do
  alias EtheloApi.Scenarios.QuadraticData
  require Logger

  def calculate_totals(import_data) do
    quad_data = QuadraticData.initialize(import_data)

    seed_data = calculate_seed_values(quad_data)
    combined_data = calculate_vote_values(quad_data, seed_data)
    final_data = calculate_final_data(quad_data, combined_data)

    build_for_output(quad_data, final_data)
  end

  def empty_output do
    %{global: %{}, by_oc: []}
  end

  def build_for_output(quad_data, final_data) do
    base =
      Map.take(quad_data, [
        :user_seeds,
        :total_available,
        :cutoff,
        :seed_allocation_percent,
        :vote_allocation_percent,
        :maximum_allocation,
        :round_to,
        :seed_allocation_target,
        :vote_allocation_target,
        :seeds_assigned_total,
        :positive_seed_votes_sum,
        :positive_seed_votes_sq_sum
      ])

    calculated =
      Map.take(final_data, [
        :seed_allocation_total,
        :vote_allocation_total,
        :combined_allocation_total,
        :final_allocation_total,
        :remaining_after_seed
      ])

    # copy totals with name used by ScenarioStats
    global =
      Map.merge(base, calculated)
      |> Map.put(:seed_allocation, final_data.seed_allocation_total)
      |> Map.put(:vote_allocation, final_data.vote_allocation_total)
      |> Map.put(:combined_allocation, final_data.combined_allocation_total)
      |> Map.put(:final_allocation, final_data.final_allocation_total)
      |> Map.put(:seeds_assigned, quad_data.seeds_assigned_total)
      |> Map.put(:positive_seed_votes_sq, quad_data.positive_seed_votes_sq_sum)
      |> Map.put(:positive_seed_votes_sum, quad_data.positive_seed_votes_sum)

    by_oc =
      final_data.oc_seed_allocations
      |> Map.keys()
      |> Enum.reduce(%{}, fn oc_id, memo ->
        oc_data =
          Map.get(memo, oc_id, %{})
          |> Map.put(:seed_allocation, final_data.oc_seed_allocations[oc_id])
          |> Map.put(:vote_allocation, final_data.oc_vote_allocations[oc_id])
          |> Map.put(:combined_allocation, final_data.oc_combined_allocations[oc_id])
          |> Map.put(:final_allocation, final_data.oc_final_allocations[oc_id])
          |> Map.put(:positive_seed_votes_sq, quad_data.positive_seed_votes_sq_by_oc[oc_id])
          |> Map.put(:positive_seed_votes_sum, quad_data.positive_seed_votes_sum_by_oc[oc_id])
          |> Map.put(:seeds_assigned, quad_data.seeds_assigned_by_oc[oc_id])

        Map.put(memo, oc_id, oc_data)
      end)

    %{global: global, by_oc: by_oc}
  end

  def calculate_seed_values(quad_data) do
    # round 1, figure out seed values
    oc_seed_allocations =
      quad_data.seeds_assigned_by_oc
      |> Enum.reduce(%{}, fn {oc_id, seeds}, memo ->
        allocation = calculate_seed_allocation(seeds, quad_data)
        Map.put(memo, oc_id, allocation)
      end)

    seed_allocation_total = oc_seed_allocations |> Map.values() |> Enum.sum()
    remaining_after_seed = quad_data.total_available - seed_allocation_total

    %{
      oc_seed_allocations: oc_seed_allocations,
      seed_allocation_total: seed_allocation_total,
      remaining_after_seed: remaining_after_seed
    }
  end

  def calculate_seed_allocation(oc_seed_count, quad_data) do
    (quad_data.seed_allocation_target * oc_seed_count / quad_data.seeds_assigned_total)
    |> round()
  end

  def calculate_vote_values(quad_data, seed_data) do
    oc_vote_allocations =
      quad_data.positive_seed_votes_sq_by_oc
      |> Enum.reduce(%{}, fn {oc_id, votes}, memo ->
        allocation = calculate_vote_allocation(votes, quad_data, seed_data.remaining_after_seed)
        Map.put(memo, oc_id, allocation)
      end)

    vote_allocation_total = oc_vote_allocations |> Map.values() |> Enum.sum()

    seed_data
    |> Map.put(:oc_vote_allocations, oc_vote_allocations)
    |> Map.put(:vote_allocation_total, vote_allocation_total)
  end

  def calculate_vote_allocation(oc_vote_count, quad_data, remaining_after_seed) do
    (oc_vote_count * remaining_after_seed / quad_data.positive_seed_votes_sq_sum)
    |> round()
  end

  def calculate_final_data(quad_data, combined_data) do
    oc_combined_allocations =
      combined_data.oc_seed_allocations
      |> Map.keys()
      |> Enum.map(fn oc_id ->
        combined =
          combined_data.oc_seed_allocations[oc_id] + combined_data.oc_vote_allocations[oc_id]

        {oc_id, combined}
      end)
      |> Enum.into(%{})

    combined_allocation_total = oc_combined_allocations |> Map.values() |> Enum.sum()

    combined_data =
      combined_data
      |> Map.put(:oc_combined_allocations, oc_combined_allocations)
      |> Map.put(:combined_allocation_total, combined_allocation_total)

    oc_final_allocations =
      oc_combined_allocations
      |> Enum.map(fn {oc_id, amount} ->
        after_cutoff =
          case amount < quad_data.cutoff do
            true -> 0
            false -> amount_within_limits(amount, quad_data)
          end

        {oc_id, after_cutoff}
      end)
      |> Enum.into(%{})

    final_allocation_total = oc_final_allocations |> Map.values() |> Enum.sum()

    combined_data
    |> Map.put(:oc_final_allocations, oc_final_allocations)
    |> Map.put(:final_allocation_total, final_allocation_total)
  end

  def amount_within_limits(amount, %{round_to: round_to, maximum_allocation: max_a}) do
    rounded = round_to * round(amount / round_to)
    min(rounded, max_a)
  end
end
