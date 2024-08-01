defmodule Engine.Invocation.ScoringData do
  @moduledoc """
  Registry of data associated with an engine invocation
  """

  import Ecto.Query
  import EtheloApi.Helpers.ExportHelper
  import Engine.Invocation.DecisionMapLoader

  alias EtheloApi.Repo
  alias Engine.Invocation.ScoringData
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  alias Engine.Scenarios
  alias Engine.Scenarios.QuadraticBuilder
  alias Engine.Scenarios.ScenarioConfig
  alias EtheloApi.Voting.Participant

  defstruct [
    :auto_constraints,
    :bin_votes,
    :bin_votes_by_option,
    :calculations,
    :calculations_by_slug,
    :constraints,
    :constraints_by_slug,
    :criterias,
    :criterias_by_slug,
    :criteria_weights,
    :criteria_weights_by_criteria,
    :decision,
    :decision_id,
    :options,
    :options_by_id,
    :options_by_slug,
    :options_by_oc,
    :option_categories,
    :option_categories_by_id,
    :option_categories_by_slug,
    :option_category_range_votes,
    :option_category_range_votes_by_oc,
    :option_category_weights,
    :option_category_weights_by_oc,
    :option_details,
    :option_details_by_id,
    :option_detail_values,
    :option_filters,
    :option_ids_by_filter_id,
    :option_ids_by_filter_slug,
    :participants,
    :quadratic_totals,
    :scenario_config,
    :voting_participant_ids,
    :variables,
  ]

  def initialize_decision_json_data(decision, enabled_only \\ true, exclude_deleted \\ true) do
    initialize_common_data(decision, enabled_only, exclude_deleted)
    |> add_decision_json_data(enabled_only, exclude_deleted)
  end

  def initialize_all_voting(
        decision,
        scenario_config_id \\ nil,
        enabled_only \\ true,
        exclude_deleted \\ true
      ) do
    initialize_common_data(decision, enabled_only, exclude_deleted)
    |> add_all_voting_data()
    |> finalize_voting_data(scenario_config_id)
  end

  def initialize_single_voting(
        decision,
        participant_id,
        scenario_config_id \\ nil,
        enabled_only \\ true,
        exclude_deleted \\ true
      ) do
    initialize_common_data(decision, enabled_only, exclude_deleted)
    |> add_personal_voting_data(participant_id)
    |> finalize_voting_data(scenario_config_id)
  end

  def initialize_common_data(
        decision,
        enabled_only \\ true,
        exclude_deleted \\ true
      )

  def initialize_common_data(decision_id, enabled_only, exclude_deleted)
      when is_integer(decision_id) do
    EtheloApi.Structure.get_decision(decision_id)
    |> initialize_common_data(enabled_only, exclude_deleted)
  end

  def initialize_common_data(%Decision{id: decision_id} = decision, enabled_only, exclude_deleted) do
    common = %Engine.Invocation.ScoringData{
      decision: decision |> clean_map(),
      decision_id: decision_id,
      criterias:
        criteria_data(decision_id) |> filter_maps(enabled_only, exclude_deleted) |> sort_by_slug(),
      options:
        option_data(decision_id) |> filter_maps(enabled_only, exclude_deleted) |> sort_by_slug(),
      option_categories:
        option_category_data(decision_id) |> filter_maps(enabled_only, exclude_deleted),
      option_details: option_detail_data(decision_id),
      option_detail_values: option_detail_value_data(decision_id)
    }

    indexed = %{
      criterias_by_slug: common.criterias |> group_by_slug(),
      option_categories_by_id: common.option_categories |> group_by_id(),
      option_categories_by_slug: common.option_categories |> group_by_slug(),
      options_by_slug: common.options |> group_by_slug(),
      options_by_id: common.options |> group_by_id(),
      options_by_oc: common.options |> group_by_option_category(),
      option_details_by_id: common.option_details |> group_by_id(),
    }

    Map.merge(common, indexed)
  end

  def add_decision_json_data( data, enabled_only \\ true, exclude_deleted \\ true)
  def add_decision_json_data(
        %ScoringData{decision_id: decision_id, auto_constraints: nil} = data,
        enabled_only,
        exclude_deleted
      ) do
    data =
      data
      |> Map.put(:option_filters, option_filter_data(decision_id))
      |> Map.put(:variables, variable_data(decision_id))
      |> add_calculations_and_constraints(enabled_only, exclude_deleted)

    %{slugs: by_slugs, ids: by_ids} = Structure.option_ids_matching_filter_data(data)

    data
      |> Map.put(:option_ids_by_filter_slug, by_slugs)
      |> Map.put(:option_ids_by_filter_id, by_ids)
      |> Map.put(:auto_constraints, generate_auto_constraints(data.option_categories, data))
  end
  # assume already added
  def add_decision_json_data( data, _, _ ), do: data

  def add_calculations_and_constraints( data ,enabled_only \\ true,  exclude_deleted \\ true)
  def add_calculations_and_constraints(%ScoringData{decision_id: decision_id, calculations: nil} = data,
       enabled_only ,
        exclude_deleted \
  ) do
    data
    |> Map.put(:calculations, calculation_data(decision_id))
    |> Map.put(
      :constraints,
      constraint_data(decision_id) |> filter_maps(enabled_only, exclude_deleted)
    )
  end
  # assume already added
  def add_calculations_and_constraints( data, _, _ ), do: data

  def add_scenario_import_data(%ScoringData{bin_votes: nil}) do
    raise(ArgumentError, message: "Voting data must be initalized first" )
  end

  def add_scenario_import_data(%ScoringData{bin_votes_by_option: nil} = voting_data) do
    voting_data = voting_data |> add_calculations_and_constraints(false, false)

    voting_data
    |> Map.put(:calculations_by_slug, voting_data.calculations |> group_by_slug())
    |> Map.put(:constraints_by_slug, voting_data.constraints |> group_by_slug())
    |> Map.put(:criteria_weights_by_criteria, voting_data.criteria_weights |> group_by_criteria())
    |> Map.put(
      :option_category_weights_by_oc,
      voting_data.option_category_weights |> group_by_option_category()
    )
    |> Map.put(:bin_votes_by_option, voting_data.bin_votes |> group_by_option())
    |> Map.put(
      :option_category_range_votes_by_oc,
      voting_data.option_category_range_votes |> group_by_option_category()
    )
    |> add_quadratic_data()
  end
  # assume already added
  def add_scenario_import_data(data), do: data

  def add_quadratic_data(%{scenario_config: %{quadratic: true}, quadratic_totals: nil} = voting_data) do
    voting_data
      |> Map.put( :quadratic_totals, QuadraticBuilder.calculate_totals(voting_data) )
  end
  def add_quadratic_data(voting_data) do
    voting_data
      |> Map.put( :quadratic_totals, QuadraticBuilder.empty_output() )
  end

  def finalize_voting_data(%ScoringData{} = data, scenario_config_id) do
    data
    |> add_scenario_config(scenario_config_id)
    |> filter_valid_votes()
    |> filter_to_voting_participants()
  end

  def add_all_voting_data(%ScoringData{participants: participants} = data)
      when is_list(participants) do
    # assume already loaded, don't reload
    data
  end

  def add_all_voting_data(%ScoringData{decision_id: decision_id, participants: nil} = data) do
    data
    |> Map.put(:bin_votes, bin_vote_data(decision_id))
    |> Map.put(:option_category_weights, option_category_weight_data(decision_id))
    |> Map.put(:criteria_weights, criteria_weight_data(decision_id))
    |> Map.put(:option_category_range_votes, option_category_range_vote_data(decision_id))
    |> Map.put(:participants, participant_data(decision_id))
  end

  def add_personal_voting_data(%ScoringData{participants: participants} = data, _)
      when is_list(participants) do
    # assume already loaded, don't reload
    data
  end

  def add_personal_voting_data(%ScoringData{participants: nil} = data, participant_id) do
    participant = participant_with_influent(participant_id)

    participant_data =
      if participant == nil do
        %{
          bin_votes: [],
          option_category_weights: [],
          criteria_weights: [],
          option_category_range_votes: [],
          participants: []
        }
      else
        # ensure weighting is present so participant is not filtered out
        participant_map =
          participant |> clean_map() |> Map.put(:weighting, Decimal.from_float(1.0))

        %{
          bin_votes: participant.bin_votes |> to_maps(),
          option_category_weights: participant.option_category_weights |> to_maps(),
          criteria_weights: participant.criteria_weights |> to_maps(),
          option_category_range_votes: participant.option_category_range_votes |> to_maps(),
          participants: [participant_map]
        }
      end

    Map.merge(data, participant_data)
  end

  def participant_with_influent(%Participant{id: participant_id}) do
    participant_with_influent(participant_id)
  end

  def participant_with_influent(participant_id) do
    Participant
    |> preload([
      :bin_votes,
      :option_category_bin_votes,
      :option_category_range_votes,
      :option_category_weights,
      :criteria_weights
    ])
    |> Repo.get(participant_id)
  end

  def add_scenario_config(
        %ScoringData{} = data,
        %ScenarioConfig{} = scenario_config
      ) do

        Map.put(data, :scenario_config, scenario_config |> clean_map())
  end

  def add_scenario_config(
        %ScoringData{scenario_config: nil, decision_id: decision_id} = data,
        scenario_config_id
      ) do

    scenario_config =
      case scenario_config_id do
        nil -> nil
        _ -> Scenarios.get_scenario_config(scenario_config_id, decision_id) |> clean_map()
      end

    Map.put(data, :scenario_config, scenario_config)
  end

  def add_scenario_config(%ScoringData{} = data, _) do
    # assume already loaded, don't reload
    data
  end

  def filter_maps(list, enabled_only, exclude_deleted) do
    list |> filter_enabled(enabled_only) |> filter_deleted(exclude_deleted)
  end

  def filter_valid_votes(data) do
    data
    |> Map.put(:bin_votes, valid_bin_votes(data))
    |> Map.put(:option_category_range_votes, valid_option_category_range_votes(data))
    |> Map.put(:criteria_weights, valid_criteria_weights(data))
    |> Map.put(:option_category_weights, valid_option_category_weights(data))
  end

  def uses_range_voting(scoring_mode) do
    case scoring_mode do
      :triangle -> true
      :rectangle -> true
      nil -> false
      _ -> false
    end
  end

  def uses_bin_voting(scoring_mode) do
    case scoring_mode do
      :triangle -> false
      :rectangle -> false
      nil -> false
      _ -> true
    end
  end

  def valid_bin_votes(data) do
    enabled_option_ids = data.options |> Enum.map(& &1.id)

    option_categories_by_id = data.option_categories |> group_by_id()

    bin_vote_option_ids =
      Enum.map(data.options, fn option ->
        option_category =
          option_categories_by_id[option.option_category_id] || %{scoring_mode: nil}

        if uses_bin_voting(option_category.scoring_mode) do
          option.id
        else
          nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    data.bin_votes
    |> filter_by_option(enabled_option_ids)
    |> filter_by_option(bin_vote_option_ids)
  end

  def valid_option_category_range_votes(data) do
    Enum.filter(data.option_category_range_votes, fn range_vote ->
      option_category =
        data.option_categories_by_id[range_vote.option_category_id] || %{scoring_mode: nil}

      uses_range_voting(option_category.scoring_mode)
    end)
  end

  def valid_option_category_weights(data) do
    Enum.filter(data.option_category_weights, fn option_category_weight ->
      option_category =
        data.option_categories_by_id[option_category_weight.option_category_id] ||
          %{apply_participant_weights: false}

      option_category.apply_participant_weights
    end)
  end

  def valid_criteria_weights(data) do
    criteria_by_id = data.criterias |> group_by_id()

    Enum.filter(data.criteria_weights, fn criteria_weight ->
      criteria =
        criteria_by_id[criteria_weight.criteria_id] || %{apply_participant_weights: false}

      criteria.apply_participant_weights
    end)
  end

  def filter_by_option(list, option_ids) do
    Enum.filter(list, fn record -> record.option_id in option_ids end)
  end

  def filter_by_participant(list, participant_ids) do
    Enum.filter(list, fn record -> MapSet.member?(participant_ids, record.participant_id) end)
  end

  def participants_without_influence(participants) do
    participants
    |> Enum.reject(fn participant ->
      cmp = Decimal.cmp(Decimal.from_float(0.0), participant.weighting)
      cmp != :eq
    end)
    |> Enum.map(& &1.id)
    |> MapSet.new()
  end

  def participants_with_votes(votes) do
    votes
    |> Enum.map(& &1.participant_id)
    |> MapSet.new()
  end

  def voting_participant_ids(data) do
    with_votes =
      Enum.concat(data.bin_votes, data.option_category_range_votes)
      |> participants_with_votes()

    without_influence = participants_without_influence(data.participants)

    MapSet.difference(with_votes, without_influence) |> Enum.sort() |> MapSet.new()
  end

  def filter_to_voting_participants(data) do
    voting_participant_ids = data |> voting_participant_ids()

    data
    |> Map.put(:bin_votes, data.bin_votes |> filter_by_participant(voting_participant_ids))
    |> Map.put(
      :option_category_range_votes,
      data.option_category_range_votes |> filter_by_participant(voting_participant_ids)
    )
    |> Map.put(
      :criteria_weights,
      data.criteria_weights |> filter_by_participant(voting_participant_ids)
    )
    |> Map.put(
      :option_category_weights,
      data.option_category_weights |> filter_by_participant(voting_participant_ids)
    )
    |> Map.put(
      :participants,
      data.participants
      |> Enum.filter(fn participant -> MapSet.member?(voting_participant_ids, participant.id) end)
    )
    |> Map.put(:voting_participant_ids, voting_participant_ids)
  end

  defp all_options_filter_id(option_filters) do
    option_filters
    |> Enum.find(&(Map.get(&1, :match_mode, nil) === "all_options"))
    |> case do
      nil -> nil
      first -> Map.get(first, :id)
    end
  end

  defp generate_auto_constraints([], _), do: []
  defp generate_auto_constraints(nil, _), do: []

  defp generate_auto_constraints(option_categories, data) do
    xor_ids =
      option_categories
      |> Enum.filter(&Map.get(&1, :xor, true))
      |> Enum.filter(fn option_category ->
        Enum.any?(data.options, fn option -> option.option_category_id == option_category.id end)
      end)
      |> Enum.map(& &1.id )

    option_filter_ids =
      data.option_filters
      |> Enum.filter(fn option_filter -> option_filter.option_category_id in xor_ids end)
      |> Enum.map(&Map.get( &1, :id))

    variables =
      data.variables
      |> Enum.filter(fn variable -> variable.option_filter_id in option_filter_ids end)
      |> Enum.filter(&(Map.get(&1, :method) == :count_selected))

    variables
    |> Enum.map(fn variable ->
      %{
        slug: "__auto_xor#{variable.id}",
        title: "__auto_xor#{variable.id}",
        operator: :equal_to,
        lhs: nil,
        rhs: 1.0,
        enabled: true,
        relaxable: true,
        variable_id: variable.id,
        calculation_id: nil,
        public: false,
        option_filter_id: all_options_filter_id(data.option_filters)
      }
    end)
  end
end
