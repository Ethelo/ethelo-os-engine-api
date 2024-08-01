defmodule Engine.Scenarios.Calculators.HistogramCalculator do
  use Ecto.Schema
  alias Engine.Invocation.ScoringData
  alias Engine.Invocation.InfluentsJson
  import EtheloApi.Helpers.ExportHelper

  def bin_vote_histogram(%{scenario_config: config} = voting_data, %{
        option: option,
        criteria: criteria
      }) do

    voting_data.bin_votes_by_option
    |> Map.get(option.id, [])
    |> Enum.filter(fn bin_vote -> bin_vote.criteria_id == criteria.id end)
    |> convert_to_bin_histogram(config.bins)
  end

  def bin_vote_histogram(%{scenario_config: config} = voting_data, %{option: option}) do
    option_category = voting_data.option_categories_by_id[option.option_category_id]

    bin_votes =
      cond do
        is_nil(option_category) ->
          %{}

        ScoringData.uses_bin_voting(option_category.scoring_mode) ->
          voting_data.bin_votes_by_option

        true ->
          voting_data
          |> InfluentsJson.convert_range_votes_to_vote_maps()
          |> group_by_option()
      end

    bin_votes
    |> Map.get(option.id, [])
    |> convert_to_bin_histogram(config.bins)
  end

  def bin_vote_histogram(_, _), do: []

  def convert_to_bin_histogram(bin_votes, bin_count) do
    vote_counts =
      bin_votes
      |> group_by_key(:bin)
      |> Enum.reduce(%{}, fn {bin, vote_list}, memo ->
        memo |> Map.put(bin, length(vote_list))
      end)

    1..bin_count
    |> Enum.map(fn bin ->
      Map.get(vote_counts, bin, 0)
    end)
  end


  def vote_spectrum([]) do
    %{
      negative_votes: 0,
      neutral_votes: 0,
      positive_votes: 0
    }
  end

  def vote_spectrum(histogram) when is_list(histogram) do
    length = length(histogram)

    spectrum = %{
      negative_votes: 0,
      neutral_votes: 0,
      positive_votes: 0
    }

    middle_index = length / 2
      |> Float.floor()
      |> round()

    histogram
    |> Enum.with_index()
    |> Enum.reduce(spectrum, fn {count, index}, spectrum ->
      key =
        cond do
          index < middle_index -> :negative_votes
          index == middle_index -> :neutral_votes
          index > middle_index -> :positive_votes
        end

      current_value = Map.get(spectrum, key)
      Map.put(spectrum, key, current_value + count)
    end)
  end

  # TODO this needs to be updated when we support actual ranges
  # to include everything in the range instead of just checking high/low
  def option_range_vote_counts(%{} = voting_data, %{option: option}) do
    category_votes =
      voting_data.option_category_range_votes_by_oc
      |> Map.get(option.option_category_id, [])

    total_count = Enum.count(category_votes)

    option_count =
      category_votes
      |> Enum.filter(fn ocrv -> option.id in [ocrv.low_option_id, ocrv.high_option_id] end)
      |> Enum.count()

    [option_count, total_count]
  end

  def option_range_vote_counts(_, _), do: []


end
