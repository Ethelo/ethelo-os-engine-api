defmodule Engine.Invocation.InfluentsJson do
  import EtheloApi.Helpers.ExportHelper
  import EtheloApi.Constraints.ValueParser
  require Logger

  defp map_bins_to_engine_floats(%{scenario_config: %{bins: 1}}) do
    %{1 => 1.0}
  end
  defp map_bins_to_engine_floats(%{scenario_config: scenario_config}) do
    1..scenario_config.bins
      |> Enum.map(fn(bin) ->
        value = if scenario_config.support_only do
            (bin - 1) / (scenario_config.bins - 1)
        else
            (bin - 1) / (scenario_config.bins - 1) * 2 - 1
        end
        {bin, value}
      end)
      |> Enum.into(%{})
  end

  def convert_range_votes_to_vote_maps(voting_data) do
    voting_data.option_category_range_votes
    |> Enum.reduce([], fn ocrv, memo ->
      oc_id = ocrv.option_category_id
      option_category = voting_data.option_categories_by_id[oc_id]
      oc_options = voting_data.options_by_oc[oc_id]

      sorted_options =
        sort_options_by_detail(oc_options, voting_data, option_category.primary_detail_id)

      new_votes = bin_votes_from_range_vote(ocrv, option_category, sorted_options, voting_data)
      Enum.concat(new_votes, memo)
    end)
  end

  def bin_votes_from_range_vote(_, nil, _, _), do: []
  def bin_votes_from_range_vote(_, _, nil, _), do: []
  def bin_votes_from_range_vote(_, _, [], _), do: []
  def bin_votes_from_range_vote(_, %{scoring_mode: :none}, _, _), do: []
  # only handles rectangle single option votes
  def bin_votes_from_range_vote(ocrv, %{scoring_mode: :rectangle}, sorted_options, voting_data) when is_list(sorted_options) do
    sorted_options |> Enum.map(fn(option) ->
      bin = cond do
          option.id == ocrv.low_option_id -> voting_data.scenario_config.bins
          true -> 1
      end
      bin_vote = %{
        option_id: option.id, participant_id: ocrv.participant_id, bin: bin,
      }

      voting_data.criterias |> Enum.map(fn(criteria) ->
        Map.put(bin_vote, :criteria_id, criteria.id)
      end)
      |> convert_bin_votes_to_vote_maps(voting_data)

    end)
    |> List.flatten()
  end

  def bin_votes_from_range_vote(ocrv, %{scoring_mode: :triangle} = oc, sorted_options, voting_data) when is_list(sorted_options) do
    selected_index = Enum.find_index(sorted_options, fn(option) ->
      ocrv.low_option_id == option.id
    end)

    base = oc.triangle_base/2.0 |> Float.ceil

    0..( Enum.count(sorted_options) - 1 )
      |> Enum.map(fn(index) ->
        engine_value = score_for_index(index, selected_index, base, voting_data.scenario_config);
        %{
          option_id: Enum.at(sorted_options, index) |> Map.get(:id),
          engine_value: engine_value,
          bin: engine_value_to_bin( engine_value, voting_data.scenario_config),
          participant_id: ocrv.participant_id,
        }
    end)
    |> Enum.map(fn(vote_map) ->
      voting_data.criterias |> Enum.map(fn(criteria) ->
        Map.put(vote_map, :criteria_id, criteria.id)
      end)
    end)
    |> List.flatten()
  end

  def bin_votes_from_range_vote(_, _, _), do: []

  def engine_value_to_bin(nil, _scenario_config), do: nil

  def engine_value_to_bin(value, %{support_only: support_only, bins: bins}) do
    min_engine = if support_only, do: 0, else: -1
    max_engine = 1

    value = if (value < min_engine), do: min_engine, else: value
    value = if (value > max_engine), do: max_engine, else: value

    bin = ((value - min_engine) / (max_engine - min_engine)) * (bins - 1) + 1
    trunc(bin)
  end

  def score_for_index(nil, _, _, _), do: 1.0
  def score_for_index(index, selected_index, base, %{support_only: support_only}) do
    #index = 0
    difference = abs(selected_index - index) # 3 - 0 = 3

    score = cond do
      difference == 0 -> 1.0
      difference >= base -> 0.0
      true -> abs((difference/base) - 1)
    end

    score = if support_only do
      score
    else
      score * 2 - 1
     end

    score
  end

  def sort_options_by_detail(_, _, nil), do: []
  def sort_options_by_detail(nil, _, _), do: []
  def sort_options_by_detail([], _, _), do: []

  def sort_options_by_detail(options, voting_data, option_detail_id) do
    option_detail = voting_data.option_details_by_id[option_detail_id]

    option_detail_id =
      case option_detail do
        %{id: _} -> option_detail_id
        _ -> nil
      end

    option_ids = options |> Enum.map(&( &1.id) )

    voting_data.option_detail_values
    |> Enum.filter(fn odv ->
      odv.option_detail_id === option_detail_id && Enum.member?(option_ids, odv.option_id)
    end)
    |> Enum.map(fn odv -> odv_to_map(odv, option_detail) end)
    |> Enum.sort_by(&Map.get(&1, :value))
    |> Enum.map(fn map_value ->
      Map.get(voting_data.options_by_id, Map.get(map_value, :option_id))
    end)
  end

  defp odv_to_map(odv, option_detail) do
    str_value = to_matchable_string(odv.value, option_detail.format)

    # should invalid values be skipped or set to 0 before sending to engine?
    float_val = case str_value do
      {:ok, value} -> to_float(value)
      _ -> 0
    end

    %{
        option_id: odv.option_id,
        value: float_val
      }
  end

  defp create_vote_maps(voting_data) do
    converted_votes = voting_data |> convert_range_votes_to_vote_maps()
    filtered_votes = convert_bin_votes_to_vote_maps(voting_data.bin_votes, voting_data)
    Enum.concat(converted_votes, filtered_votes)
      |> List.flatten()
      |> Enum.group_by(&(Map.get(&1, :participant_id)))
      |> Enum.map(fn ({participant_id, vote_maps}) ->
        values_by_id = vote_maps
          |> Enum.map(fn(vote_map) -> Map.put(vote_map, :id, vote_key(vote_map)) end)
          |> group_by_key(:id)
          |> delist_group()
        {participant_id, values_by_id}
      end)
      |> Enum.into(%{})
  end

  defp vote_key(%{option_id: option_id, criteria_id: criteria_id}) do
    "#{option_id}-#{criteria_id}"
  end

  defp convert_bin_votes_to_vote_maps(list, voting_data) do
    bins_to_floats = map_bins_to_engine_floats(voting_data)
    bin_count = voting_data.scenario_config.bins

    list |> Enum.map(fn(bin_vote) ->
      value = cond do
          bin_vote.bin > bin_count -> Map.get(bins_to_floats, bin_count)
          bin_vote.bin < 1 -> Map.get(bins_to_floats, 1)
          true -> Map.get(bins_to_floats, bin_vote.bin)
        end

      %{
        engine_value: value,
        bin: bin_vote.bin, # needed for some post processing
        criteria_id: bin_vote.criteria_id,
        option_id: bin_vote.option_id,
        participant_id: bin_vote.participant_id,
      }
    end)
  end

  defp build_influents_matrix(influents, voting_data) do
    sorted_criteria = Enum.sort_by(voting_data.criterias, &(&1.slug))
    sorted_options = Enum.sort_by(voting_data.options, &(&1.slug))
    voting_data.voting_participant_ids |> Enum.map(fn(participant_id) ->
        sorted_options |> Enum.flat_map(fn(option) ->
          sorted_criteria |> Enum.map(fn(criteria) ->
            get_in(influents, [participant_id, "#{option.id}-#{criteria.id}", :engine_value])
          end)
        end)
    end)
  end

  def build(%{} = voting_data) do
    voting_data
    |> create_vote_maps()
    |> build_influents_matrix(voting_data)
  end

  def to_json(map, pretty \\ true), do: Poison.encode!(map, pretty: pretty)

  # should always be valid because we're getting it from matchable string
  defp to_float(value) do
    case Float.parse(value) do
      {number, _} -> number
      :error -> 0
    end
  end
end
