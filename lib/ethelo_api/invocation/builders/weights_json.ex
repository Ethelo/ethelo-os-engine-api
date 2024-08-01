defmodule EtheloApi.Invocation.WeightsJson do
  import EtheloApi.Helpers.ExportHelper

  # weighting locations
  # criterias[0].weighting - default or overridden weight set by admin for a Criteria. 1-100, integers
  # option_category[0].weighting - default or overridden weight set by admin for all Options in an OptionCategory. 1-100, integers
  # option_category_weights - Participant associated weights to apply to all Options in an OptionCategory 1-100, integers
  # criteria_weights - Participant associated weights to apply to all votes to Criteria 1-100, integers
  # participant_weights - weights for Participant set by an admin.  Weight set by admin to be multiplied by all votes by Participant. Weight of 0 indicates all votes by this Participant should be excluded. 0-? (ask John). Decimal 4, 2 ?
  # bin_votes - votes made by Participants on a particular Criteria + Option combo. Bin number indicates which bin they clicked, and should be
  # cross referenced with the Criteria to see the number of bins configured (Criteria.bins) and if they are positive only or positive to negative (Criteria.support_only). Theoretically if the bin range changes all votes will be updated to correct values, but some handling should be included for out of range bins.  1-max number of bins

  def get_record_weight(%{weighting: weighting}, _) when is_number(weighting) do
    weighting
  end

  def get_record_weight(%{weighting: %Decimal{} = weighting}, _) do
    Decimal.to_float(weighting)
  end

  def get_record_weight(_, default), do: default

  defp normalize_weight_map(weight_map) do
    weight_map =
      weight_map
      |> List.flatten()
      |> Enum.reject(fn
        {_, nil} -> true
        _ -> false
      end)
      |> Enum.into(%{})

    total = weight_map |> Map.values() |> Enum.map(& &1.weight) |> Enum.sum()

    weight_map
    |> Enum.map(fn
      {key, %{weight: weight, arity: arity}} ->
        {key, weight / (total * arity)}
    end)
    |> Map.new()
  end

  def weighted_record_map(_, 0, _), do: nil

  def weighted_record_map(record, arity, nil) do
    %{arity: arity, weight: get_record_weight(record, 100) / 100.0}
  end

  def weighted_record_map(%{apply_participant_weights: false} = record, arity, _) do
    %{arity: arity, weight: get_record_weight(record, 100) / 100.0}
  end

  def weighted_record_map(%{apply_participant_weights: true} = record, arity, participant_weight) do
    weight = get_record_weight(participant_weight, get_record_weight(record, 100))

    %{arity: arity, weight: weight / 100.0}
  end

  def normalized_option_category_weights(voting_data) do
    lengths = option_category_lengths(voting_data)

    ocw_by_participant = voting_data.option_category_weights |> group_by_participant()

    voting_data.participants
    |> Enum.map(fn participant ->
      ocws =
        (ocw_by_participant[participant.id] || []) |> group_by_option_category() |> delist_group()

      voting_data.option_categories
      |> Enum.map(fn option_category ->
        option_category_weight = ocws[option_category.id]

        arity = Map.get(lengths, option_category.id, 0)

        value = weighted_record_map(option_category, arity, option_category_weight)

        {{option_category.id, participant.id}, value}
      end)
    end)
    |> normalize_weight_map()
  end

  def option_category_lengths(voting_data) do
    voting_data.options_by_oc
    |> Enum.map(fn {oc_id, list} ->
      {oc_id, length(list)}
    end)
    |> Enum.into(%{})
  end

  def normalized_criteria_weights(voting_data) do
    cw_by_participant = voting_data.criteria_weights |> group_by_participant()

    voting_data.participants
    |> Enum.map(fn participant ->
      cws = (cw_by_participant[participant.id] || []) |> group_by_criteria() |> delist_group()

      voting_data.criterias
      |> Enum.map(fn criteria ->
        criteria_weight = cws[criteria.id]

        value = weighted_record_map(criteria, 1, criteria_weight)

        {{criteria.id, participant.id}, value}
      end)
    end)
    |> normalize_weight_map()
  end

  def normalized_participant_weights(voting_data) do
    weights =
      Enum.map(voting_data.participants, fn participant ->
        get_record_weight(participant, 1)
      end)

    participant_weight_max = Enum.max([1] ++ weights)

    voting_data.participants
    |> Enum.reduce(%{}, fn participant, memo ->
      weight = get_record_weight(participant, 1) * (1.0 / participant_weight_max)
      Map.put(memo, participant.id, weight)
    end)
  end

  def build_normalized_weights(voting_data) do
    %{
      option_category: normalized_option_category_weights(voting_data),
      criteria: normalized_criteria_weights(voting_data),
      participant: normalized_participant_weights(voting_data)
    }
  end

  def calculate_influent_weight(normalized_weights, option, criteria, participant) do
    oc_weight =
      Map.get(
        normalized_weights.option_category,
        {option.option_category_id, participant.id},
        0.0
      )

    criteria_weight = Map.get(normalized_weights.criteria, {criteria.id, participant.id}, 0.0)
    participant_weight = Map.get(normalized_weights.participant, participant.id, 0.0)

    oc_weight * criteria_weight * participant_weight
  end

  defp build_influent_weights(voting_data) do
    normalized_weights = build_normalized_weights(voting_data)
    # each Participant / Option / Criteria combination gets a weight
    # %{participant_id: %{criteria_id: %{option_id: weight}}}
    Enum.map(voting_data.participants, fn participant ->
      by_criteria =
        Enum.map(voting_data.criterias, fn criteria ->
          by_option =
            Enum.map(voting_data.options, fn option ->
              weight =
                calculate_influent_weight(normalized_weights, option, criteria, participant)

              {option.id, weight}
            end)
            |> Enum.into(%{})

          {criteria.id, by_option}
        end)
        |> Enum.into(%{})

      {participant.id, by_criteria}
    end)
    |> Enum.into(%{})
  end

  defp build_sorted_matrix(influent_weights, voting_data) do
    sorted_criteria = Enum.sort_by(voting_data.criterias, & &1.slug)
    sorted_options = Enum.sort_by(voting_data.options, & &1.slug)

    voting_data.voting_participant_ids
    |> Enum.map(fn participant_id ->
      sorted_options
      |> Enum.flat_map(fn option ->
        sorted_criteria
        |> Enum.map(fn criteria ->
          influent_weights
          |> Map.get(participant_id, %{})
          |> Map.get(criteria.id, %{})
          |> Map.get(option.id, 0.0)
        end)
      end)
    end)
  end

  def build(%{} = voting_data) do
    voting_data
    |> build_influent_weights()
    |> build_sorted_matrix(voting_data)
  end

  def weight_list_to_average(%{} = voting_voting_data, weights, default_weight) do
    with_default = length(voting_voting_data.participants) - length(weights)

    average =
      case weights do
        [] ->
          default_weight

        _ ->
          (Enum.sum(weights) + with_default * default_weight) / (length(weights) + with_default)
      end

    %{average_weight: average}
  end

  def compute_average_weights(_, %{criteria: %{apply_participant_weights: false}} = assocs) do
    %{average_weight: get_record_weight(assocs.criteria, 100)}
  end

  def compute_average_weights(_, %{option_category: %{apply_participant_weights: false}} = assocs) do
    %{average_weight: get_record_weight(assocs.option_category, 100)}
  end

  def compute_average_weights(%{} = voting_voting_data, %{criteria: criteria}) do
    default_weight = get_record_weight(criteria, 100)

    weights =
      voting_voting_data.criteria_weights_by_criteria
      |> Map.get(criteria.id, [])
      |> Enum.map(fn criteria_weight -> get_record_weight(criteria_weight, default_weight) end)

    weight_list_to_average(voting_voting_data, weights, default_weight)
  end

  def compute_average_weights(%{} = voting_voting_data, %{option_category: option_category}) do
    default_weight = get_record_weight(option_category, 100)

    weights =
      voting_voting_data.option_category_weights_by_oc
      |> Map.get(option_category.id, [])
      |> Enum.map(fn option_category_weight ->
        get_record_weight(option_category_weight, default_weight)
      end)

    weight_list_to_average(voting_voting_data, weights, default_weight)
  end

  def compute_average_weights(_, _), do: %{average_weight: nil}

  def to_json(map, pretty \\ true), do: Jason.encode!(map, pretty: pretty)
end
