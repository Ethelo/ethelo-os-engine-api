defmodule Engine.Invocation.DecisionJson do
  @moduledoc """
  assembles the various components of an engine invocation
  """
  alias Engine.Invocation.ConstraintBuilder
  alias Engine.Invocation.FragmentBuilder
  alias Engine.Invocation.OptionBuilder
  alias Engine.Invocation.ScoringData

  require Poison

  def criteria_segment(%ScoringData{criterias_by_slug: by_slugs}) do
    slugs =
      case Map.keys(by_slugs) do
        # must always have at least one criteria
        [] ->
          ["approval"]

        slugs ->
          slugs
      end

    %{criteria: slugs}
  end

  def build(%ScoringData{} = decision_json_data) do
    %{}
    |> Map.merge(ConstraintBuilder.constraint_and_display_segments(decision_json_data))
    |> Map.merge(FragmentBuilder.fragments_segment(decision_json_data))
    |> Map.merge(OptionBuilder.options_segment(decision_json_data))
    |> Map.merge(criteria_segment(decision_json_data))
  end

  def build_json(decision_id, pretty \\ true)

  def build_json(%ScoringData{} = decision_json_data, pretty) do
    decision_json_data
    |> build()
    |> to_json(pretty)
  end

  def build_json(decision_id, pretty) when is_integer(decision_id) do
    decision_id
    |> ScoringData.initialize_decision_json_data()
    |> build()
    |> to_json(pretty)
  end

  def to_json(map, pretty \\ true), do: Poison.encode!(map, pretty: pretty)
end
