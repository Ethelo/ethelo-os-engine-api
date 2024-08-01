defmodule EtheloApi.Invocation.DecisionJson do
  @moduledoc """
  assembles the various components of an engine invocation
  """
  alias EtheloApi.Invocation.ConstraintBuilder
  alias EtheloApi.Invocation.FragmentBuilder
  alias EtheloApi.Invocation.OptionBuilder
  alias EtheloApi.Invocation.ScoringData

  defp criteria_segment(%ScoringData{criterias_by_slug: by_slugs}) do
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

  @spec build_json(identifier() | EtheloApi.Invocation.ScoringData.t()) :: String.t()
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

  def to_json(map, pretty \\ true), do: Jason.encode!(map, pretty: pretty)
end
