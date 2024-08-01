defmodule EtheloApi.Invocation.ScoringData do
  @moduledoc """
  Registry of data associated with an engine invocation
  """

  import Ecto.Query
  import EtheloApi.Helpers.ExportHelper
  import EtheloApi.Invocation.ScoringMapLoader

  alias EtheloApi.Repo
  alias EtheloApi.Invocation.ScoringData
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Scenarios.QuadraticBuilder
  alias EtheloApi.Structure.ScenarioConfig
  alias EtheloApi.Voting.Participant

  @enforce_keys [
    :decision,
    :decision_id,
    :criterias,
    :options,
    :option_categories,
    :option_details,
    :option_detail_values
  ]

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
    :variables
  ]

  @type t :: %__MODULE__{
          auto_constraints: list(map()) | nil,
          bin_votes: list(map()) | nil,
          bin_votes_by_option: map() | nil,
          calculations: list(map()) | nil,
          calculations_by_slug: map() | nil,
          constraints: list(map()) | nil,
          constraints_by_slug: map() | nil,
          criterias: list(map()),
          criterias_by_slug: map() | nil,
          criteria_weights: list(map()) | nil,
          criteria_weights_by_criteria: map() | nil,
          decision_id: integer(),
          decision: map() | nil,
          options: list(map()),
          options_by_id: map() | nil,
          options_by_slug: map() | nil,
          options_by_oc: map() | nil,
          option_categories: list(map()),
          option_categories_by_id: map() | nil,
          option_categories_by_slug: map() | nil,
          option_category_range_votes: list(map()) | nil,
          option_category_range_votes_by_oc: map() | nil,
          option_category_weights: list(map()) | nil,
          option_category_weights_by_oc: map() | nil,
          option_details: list(map()),
          option_details_by_id: map() | nil,
          option_detail_values: list(map()),
          option_filters: list(map()) | nil,
          option_ids_by_filter_id: map() | nil,
          option_ids_by_filter_slug: map() | nil,
          participants: list(map()) | nil,
          quadratic_totals: map() | nil,
          scenario_config: map(),
          voting_participant_ids: list(integer()) | nil,
          variables: list(map())
        }

  @doc """
  Initializes struct with data specifically required by `EtheloApi.Invocation.DecisionJson`
  """
  def initialize_decision_json_data(decision) do
    initialize_common_data(decision)
    |> add_decision_json_data()
  end

  @doc """
  Initializes struct with voting data for all Participants.
  This data is used by `EtheloApi.Invocation.InfluentsJson' and various Scenario post-processing calls
  """
  def initialize_all_voting(decision, scenario_config_id \\ nil) do
    initialize_common_data(decision)
    |> add_all_voting_data()
    |> finalize_voting_data(scenario_config_id)
  end

  @doc """
  Initializes struct with voting data for a single specified participant
  This data is used by `EtheloApi.Invocation.InfluentsJson' and various Scenario post-processing calls
  """
  def initialize_single_voting(
        decision,
        participant_id,
        scenario_config_id \\ nil
      ) do
    initialize_common_data(decision)
    |> add_personal_voting_data(participant_id)
    |> finalize_voting_data(scenario_config_id)
  end

  defp initialize_common_data(decision_id)
       when is_integer(decision_id) do
    EtheloApi.Structure.get_decision(decision_id)
    |> initialize_common_data()
  end

  defp initialize_common_data(%Decision{id: decision_id} = decision) do
    common = %EtheloApi.Invocation.ScoringData{
      decision: decision |> clean_map(),
      decision_id: decision_id,
      criterias: criteria_data(decision_id) |> filter_maps() |> sort_by_slug(),
      options: option_data(decision_id) |> filter_maps() |> sort_by_slug(),
      option_categories: option_category_data(decision_id) |> filter_maps(),
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
      option_details_by_id: common.option_details |> group_by_id()
    }

    Map.merge(common, indexed)
  end

  @spec add_decision_json_data(struct()) :: struct()
  defp add_decision_json_data(%ScoringData{decision_id: decision_id, auto_constraints: ac} = data)
       when ac == nil do
    data =
      data
      |> Map.put(:option_filters, option_filter_data(decision_id))
      |> Map.put(:variables, variable_data(decision_id))
      |> add_calculations_and_constraints()

    %{slugs: by_slugs, ids: by_ids} = Structure.option_ids_matching_filter_data(data)

    data
    |> Map.put(:option_ids_by_filter_slug, by_slugs)
    |> Map.put(:option_ids_by_filter_id, by_ids)
    |> Map.put(:auto_constraints, generate_auto_constraints(data.option_categories, data))
  end

  # assume already added
  defp add_decision_json_data(data), do: data

  defp add_calculations_and_constraints(
         %ScoringData{decision_id: decision_id, calculations: nil} = data
       ) do
    data
    |> Map.put(:calculations, calculation_data(decision_id))
    |> Map.put(
      :constraints,
      constraint_data(decision_id) |> filter_maps()
    )
  end

  # assume already added
  defp add_calculations_and_constraints(data), do: data

  @doc """
  Initializes struct with data specifically used by `EtheloApi.Scenarios.Queries.ScenarioImport`
  """
  def add_scenario_import_data(%ScoringData{bin_votes: nil}) do
    raise(ArgumentError, message: "Voting data must be initalized first")
  end

  def add_scenario_import_data(%ScoringData{bin_votes_by_option: nil} = voting_data) do
    voting_data = voting_data |> add_calculations_and_constraints()

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

  @doc """
  Initializes struct with data specifically used by `EtheloApi.Scenarios.Queries.ScenarioStatsBuilder`
  """
  def add_quadratic_data(
        %{scenario_config: %{quadratic: true}, quadratic_totals: nil} = voting_data
      ) do
    voting_data
    |> Map.put(:quadratic_totals, QuadraticBuilder.calculate_totals(voting_data))
  end

  def add_quadratic_data(voting_data) do
    voting_data
    |> Map.put(:quadratic_totals, QuadraticBuilder.empty_output())
  end

  defp finalize_voting_data(%ScoringData{} = data, scenario_config_id) do
    data
    |> add_scenario_config(scenario_config_id)
    |> filter_valid_votes()
    |> filter_to_voting_participants()
  end

  @spec add_all_voting_data(struct()) :: struct()
  defp add_all_voting_data(%ScoringData{decision_id: decision_id, participants: p} = data)
       when is_nil(p) do
    data
    |> Map.put(:bin_votes, bin_vote_data(decision_id))
    |> Map.put(:option_category_weights, option_category_weight_data(decision_id))
    |> Map.put(:criteria_weights, criteria_weight_data(decision_id))
    |> Map.put(:option_category_range_votes, option_category_range_vote_data(decision_id))
    |> Map.put(:participants, participant_data(decision_id))
  end

  defp add_personal_voting_data(%ScoringData{participants: p} = data, participant_id)
       when is_nil(p) do
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
        # ensure weighting is present so Participant is not filtered out
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

  defp participant_with_influent(%Participant{id: participant_id}) do
    participant_with_influent(participant_id)
  end

  defp participant_with_influent(participant_id) do
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

  defp add_scenario_config(
         %ScoringData{} = data,
         %ScenarioConfig{} = scenario_config
       ) do
    Map.put(data, :scenario_config, scenario_config |> clean_map())
  end

  defp add_scenario_config(
         %ScoringData{scenario_config: sc, decision_id: decision_id} = data,
         scenario_config_id
       )
       when is_nil(sc) do
    scenario_config =
      case scenario_config_id do
        nil -> nil
        _ -> Structure.get_scenario_config(scenario_config_id, decision_id) |> clean_map()
      end

    Map.put(data, :scenario_config, scenario_config)
  end

  defp add_scenario_config(data, _) do
    # assume already loaded, don't reload
    data
  end

  defp filter_maps(list) do
    list |> filter_enabled(true) |> filter_deleted(true)
  end

  defp filter_valid_votes(data) do
    data
    |> Map.put(:bin_votes, valid_bin_votes(data))
    |> Map.put(:option_category_range_votes, valid_option_category_range_votes(data))
    |> Map.put(:criteria_weights, valid_criteria_weights(data))
    |> Map.put(:option_category_weights, valid_option_category_weights(data))
  end

  defp uses_range_voting(scoring_mode) do
    case scoring_mode do
      :triangle -> true
      :rectangle -> true
      nil -> false
      _ -> false
    end
  end

  @spec uses_bin_voting(atom() | nil) :: boolean
  @doc """
  Determine if an OptionCategory is using a scoring mode that uses BinVotes instead of OptionCategoryRangeVotes

  ## Examples

      iex> uses_bin_votes(:triangle)
    true

    iex> uses_bin_votes(:none)
    false

  """
  def uses_bin_voting(scoring_mode) do
    case scoring_mode do
      :triangle -> false
      :rectangle -> false
      nil -> false
      _ -> true
    end
  end

  defp valid_bin_votes(data) do
    option_ids = data.options |> Enum.map(& &1.id)

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
    |> filter_by_option(option_ids)
    |> filter_by_option(bin_vote_option_ids)
  end

  defp valid_option_category_range_votes(data) do
    Enum.filter(data.option_category_range_votes, fn range_vote ->
      option_category =
        data.option_categories_by_id[range_vote.option_category_id] || %{scoring_mode: nil}

      uses_range_voting(option_category.scoring_mode)
    end)
  end

  defp valid_option_category_weights(data) do
    Enum.filter(data.option_category_weights, fn option_category_weight ->
      option_category =
        data.option_categories_by_id[option_category_weight.option_category_id] ||
          %{apply_participant_weights: false}

      option_category.apply_participant_weights
    end)
  end

  defp valid_criteria_weights(data) do
    criteria_by_id = data.criterias |> group_by_id()

    Enum.filter(data.criteria_weights, fn criteria_weight ->
      criteria =
        criteria_by_id[criteria_weight.criteria_id] || %{apply_participant_weights: false}

      criteria.apply_participant_weights
    end)
  end

  defp filter_by_option(list, option_ids) do
    Enum.filter(list, fn record -> record.option_id in option_ids end)
  end

  defp filter_by_participant(list, participant_ids) do
    Enum.filter(list, fn record -> MapSet.member?(participant_ids, record.participant_id) end)
  end

  defp participants_without_influence(participants) do
    participants
    |> Enum.reject(fn participant ->
      cmp = Decimal.compare(Decimal.from_float(0.0), participant.weighting)
      cmp != :eq
    end)
    |> Enum.map(& &1.id)
    |> MapSet.new()
  end

  defp participants_with_votes(votes) do
    votes
    |> Enum.map(& &1.participant_id)
    |> MapSet.new()
  end

  defp voting_participant_ids(data) do
    with_votes =
      Enum.concat(data.bin_votes, data.option_category_range_votes)
      |> participants_with_votes()

    without_influence = participants_without_influence(data.participants)

    MapSet.difference(with_votes, without_influence) |> Enum.sort() |> MapSet.new()
  end

  defp filter_to_voting_participants(data) do
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

  @spec generate_auto_constraints(list(map()), struct()) :: list(map())
  defp generate_auto_constraints([], _), do: []

  defp generate_auto_constraints(option_categories, data) do
    xor_ids =
      option_categories
      |> Enum.filter(fn option_category ->
        option_category.xor == true &&
          Enum.any?(data.options, fn option -> option.option_category_id == option_category.id end)
      end)
      |> Enum.map(& &1.id)

    option_filter_ids =
      data.option_filters
      |> Enum.filter(fn option_filter -> option_filter.option_category_id in xor_ids end)
      |> Enum.map(&Map.get(&1, :id))

    variables =
      data.variables
      |> Enum.filter(fn variable ->
        variable.method == :count_selected &&
          variable.option_filter_id in option_filter_ids
      end)

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
