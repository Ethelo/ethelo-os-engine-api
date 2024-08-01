defmodule EtheloApi.Voting.VoteExportData do
  @moduledoc """
  Registry of data associated with an engine invocation
  """

  alias EtheloApi.Repo
  import Ecto.Query
  import EtheloApi.Helpers.ExportHelper
  require Poison

  defstruct [
    :decision, :options, :criterias, :option_categories, :constraints, :calculations,
    :bin_votes, :option_category_range_votes, :option_category_weights,
    :option_detail_values, :option_details,
    :criteria_weights, :participants, :scenario_config, :scenario_configs,
  ]

  def vote_data_dump(decision_id) do
    decision = EtheloApi.Structure.Decision
      |> preload([
        :options, :criterias, :option_categories, :bin_votes,
        :option_category_weights, :criteria_weights, :option_category_range_votes,
        :participants
        ])
      |> Repo.get(decision_id)

      participants = decision.participants |> to_maps()
      |> Enum.reduce(%{count: 100, participants: []}, fn(participant_map, acc)  ->
         count = Map.get(acc, :count) + 1
         participant = %{
            display_id: count,
            id: Map.get(participant_map, :id),
            weighting: Map.get(participant_map, :weighting)
        }

        participants = [participant | Map.get(acc, :participants)]

        acc |> Map.put(:count, count)
            |> Map.put(:participants, participants)

      end)
      |> Map.get(:participants)
      |> group_by_id()

      context = %EtheloApi.Voting.VoteExportData{
        decision: decision |> clean_map(),
        options: decision.options |> to_maps() |> group_by_id(),
        criterias: decision.criterias |> to_maps() |> group_by_id(),
        option_categories: decision.option_categories |> to_maps()  |> group_by_id(),
        bin_votes: decision.bin_votes |> to_maps(),
        option_category_range_votes: decision.option_category_range_votes |> to_maps(),
        option_category_weights: decision.option_category_weights |> to_maps(),
        criteria_weights: decision.criteria_weights |> to_maps(),
        participants: participants,
      }


     %{
        bin_votes: context.bin_votes |> Enum.map( &(build_vote_data(&1, context)) ),
        option_category_range_votes: context.option_category_range_votes |> Enum.map(fn(bin_vote) -> build_vote_data(bin_vote, context) end),
        option_category_weights: context.option_category_weights |> Enum.map(fn(bin_vote) -> build_vote_data(bin_vote, context) end),
        criteria_weights: context.criteria_weights|> Enum.map(fn(bin_vote) -> build_vote_data(bin_vote, context) end),
        }

  end

  def to_json(result, pretty), do: Poison.encode!(result, pretty: pretty)

  def build_vote_data(record, context) do
    record = case Map.get(record, :option_id, nil) do
      nil -> record
      option_id -> Map.put(record, :option_title, get_in(context.options, [option_id, :title]) )
    end
    record = case Map.get(record, :option_category_id, nil) do
      nil -> record
      option_category_id -> Map.put(record, :option_category_title, get_in(context.option_categories, [option_category_id, :title]) )
    end
    record = case Map.get(record, :criteria_id,  nil) do
      nil -> record
      criteria_id -> Map.put(record, :criteria_title, get_in(context.criterias, [criteria_id, :title]) )
    end

    record = Map.put(record, :participant_id, get_in(context.participants, [Map.get(record, :participant_id), :id]))
    record = Map.drop(record, [:decision_id, :updated_at, :created_at, :id])

    record
  end

end
