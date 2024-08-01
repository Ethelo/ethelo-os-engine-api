defmodule EtheloApi.Scenarios.QuadraticData do
  @moduledoc """
  Registry of data associated
  with post processing for quadratic voting
  """
  alias EtheloApi.Scenarios.QuadraticData

  @enforce_keys [
    :user_seeds,
    :total_available,
    :cutoff,
    :seed_allocation_percent,
    :vote_allocation_percent,
    :maximum_allocation,
    :round_to,
    :option_category_range_votes,
    :option_detail_values,
    :seeds_assigned_by_oc,
    :positive_seed_votes_sq_by_oc,
    :positive_seed_votes_sum_by_oc
  ]

  defstruct [
    :seed_option_detail,
    :seeds_by_option,
    :user_seeds,
    :total_available,
    :cutoff,
    :seed_allocation_percent,
    :vote_allocation_percent,
    :option_category_range_votes,
    :option_detail_values,
    :seeds_assigned_by_oc,
    :seeds_assigned_total,
    :maximum_allocation,
    :round_to,
    :seed_allocation_target,
    :vote_allocation_target,
    :positive_seed_votes_sq_by_oc,
    :positive_seed_votes_sq_sum,
    :positive_seed_votes_sum_by_oc,
    :positive_seed_votes_sum
  ]

  @type t :: %__MODULE__{
          cutoff: integer(),
          maximum_allocation: integer(),
          option_category_range_votes: list(map()),
          option_detail_values: list(map()),
          positive_seed_votes_sq_by_oc: map(),
          positive_seed_votes_sq_sum: integer() | nil,
          positive_seed_votes_sum: integer() | nil,
          positive_seed_votes_sum_by_oc: map(),
          round_to: integer(),
          seeds_assigned_by_oc: map() | nil,
          seeds_assigned_total: integer() | nil,
          seeds_by_option: map() | nil,
          seed_allocation_percent: float(),
          seed_allocation_target: integer() | nil,
          seed_option_detail: map(),
          total_available: integer(),
          user_seeds: integer(),
          vote_allocation_percent: float(),
          vote_allocation_target: integer() | nil
        }

  def initialize(import_data) do
    scenario_config = import_data.scenario_config

    quad_data = %QuadraticData{
      user_seeds: scenario_config.quad_user_seeds,
      total_available: scenario_config.quad_total_available,
      cutoff: scenario_config.quad_cutoff,
      seed_allocation_percent: scenario_config.quad_seed_percent,
      vote_allocation_percent: scenario_config.quad_vote_percent,
      maximum_allocation: scenario_config.quad_max_allocation,
      round_to: scenario_config.quad_round_to,
      option_detail_values: import_data.option_detail_values,
      option_category_range_votes: import_data.option_category_range_votes,
      seeds_assigned_by_oc: %{},
      positive_seed_votes_sum_by_oc: %{},
      positive_seed_votes_sq_by_oc: %{}
    }

    # order is important as there are dependencies
    quad_data = Map.put(quad_data, :seed_option_detail, seed_option_detail(import_data))
    quad_data = Map.put(quad_data, :seeds_by_option, seeds_by_option(quad_data))

    quad_data = Map.put(quad_data, :seed_allocation_target, seed_allocation_target(quad_data))
    quad_data = Map.put(quad_data, :vote_allocation_target, vote_allocation_target(quad_data))

    %{seeds: seeds_assigned_by_oc, votes: votes_by_oc, votes_sq: votes_sq_by_oc} =
      seed_votes_by_oc(quad_data)

    quad_data = Map.put(quad_data, :seeds_assigned_by_oc, seeds_assigned_by_oc)
    quad_data = Map.put(quad_data, :seeds_assigned_total, seeds_assigned_total(quad_data))

    quad_data = Map.put(quad_data, :positive_seed_votes_sq_by_oc, votes_sq_by_oc)

    quad_data =
      Map.put(quad_data, :positive_seed_votes_sq_sum, positive_seed_votes_sq_sum(quad_data))

    quad_data = Map.put(quad_data, :positive_seed_votes_sum_by_oc, votes_by_oc)
    quad_data = Map.put(quad_data, :positive_seed_votes_sum, positive_seed_votes_sum(quad_data))

    quad_data
  end

  def positive_seed_votes_sq_sum(quad_data) do
    quad_data.positive_seed_votes_sq_by_oc |> Map.values() |> Enum.sum()
  end

  def positive_seed_votes_sum(quad_data) do
    quad_data.positive_seed_votes_sum_by_oc |> Map.values() |> Enum.sum()
  end

  def seeds_assigned_total(quad_data) do
    quad_data.seeds_assigned_by_oc |> Map.values() |> Enum.sum()
  end

  def seed_allocation_target(quad_data) do
    (quad_data.total_available * quad_data.seed_allocation_percent) |> round()
  end

  def vote_allocation_target(quad_data) do
    (quad_data.total_available * quad_data.vote_allocation_percent) |> round()
  end

  def seed_option_detail(quad_data) do
    Enum.find(quad_data.option_details, %{}, fn x -> x.slug == "seeds" end)
  end

  def seeds_by_option(%QuadraticData{seed_option_detail: %{id: option_detail_id}} = quad_data) do
    quad_data.option_detail_values
    |> Enum.filter(fn odv -> odv.option_detail_id === option_detail_id end)
    |> Enum.map(fn odv -> odv_to_seed(odv) end)
    |> Enum.filter(fn seed_info -> seed_info.seeds > 0 end)
    |> Enum.into(%{}, fn %{option_id: option_id, seeds: seeds} -> {option_id, seeds} end)
  end

  def seeds_by_option(_), do: %{}

  defp odv_to_seed(odv) do
    value = Regex.replace(~r/^\./, odv.value, "0.")

    number =
      case Float.parse(value) do
        {number, _} -> round(number)
        :error -> :error
      end

    %{option_id: odv.option_id, seeds: number}
  end

  def seed_votes_by_oc(quad_data) do
    seeds_by_option = quad_data.seeds_by_option

    base_hash = %{seeds: %{}, votes: %{}, votes_sq: %{}}

    complete_hash =
      quad_data.option_category_range_votes
      |> Enum.reduce(base_hash, fn ocrv, memo ->
        seed_count = Map.get(seeds_by_option, ocrv.low_option_id, 0)

        if seed_count == 0 do
          memo
        else
          base_seeds = Map.get(memo[:seeds], ocrv.option_category_id, 0)
          seed_list = Map.put(memo[:seeds], ocrv.option_category_id, base_seeds + seed_count)

          base_votes = Map.get(memo[:votes], ocrv.option_category_id, 0)
          vote_list = Map.put(memo[:votes], ocrv.option_category_id, base_votes + 1)

          memo
          |> Map.put(:seeds, seed_list)
          |> Map.put(:votes, vote_list)
        end
      end)

    # square count
    votes_sq =
      complete_hash.votes
      |> Enum.map(fn {oc_id, votes} -> {oc_id, votes * votes} end)
      |> Enum.into(%{})

    Map.put(complete_hash, :votes_sq, votes_sq)
  end
end
