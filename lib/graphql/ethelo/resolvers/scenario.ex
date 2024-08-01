defmodule GraphQL.EtheloApi.Resolvers.Scenario do
  @moduledoc """
  Resolvers for graphql.
  """

  alias Engine.Scenarios
  alias Engine.Scenarios.ScenarioSet
  alias Engine.Scenarios.Scenario

  alias Kronky.ValidationMessage
  import GraphQL.EtheloApi.ResolveHelper
  import GraphQL.EtheloApi.BatchHelper

  @doc """
  lists all scenarios in a scenario_set

  See `Engine.Scenarios.list_scenarios/1` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def list(%ScenarioSet{} = scenario_set, modifiers, _resolution) do
    scenario_set |> Scenarios.list_scenarios(modifiers) |> success()
  end
  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  counts scenarios in a scenario_set
  """
  def count(%ScenarioSet{} = scenario_set, modifiers, _resolution) do
    scenario_set |> Scenarios.list_scenarios(modifiers) |> length |> success()
  end
  def count(_, _, _resolution), do: {:ok, 0}

  @doc """
  lists all scenario in a scenario_set

  See `EtheloApi.Structure.match_scenarios/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def match_scenarios(args = %{scenario_set: %ScenarioSet{} = scenario_set}, _resolution) do
    scenario = args |> extract_filters() |> Scenarios.match_scenarios(scenario_set)

    case scenario do
      nil -> {:ok, %ValidationMessage{field: :filters, code: :not_found, message: "does not exist", template: "does not exist"}}
      %Scenario{} -> %{scenario: scenario} |> success()
    end
  end

  def extract_filters(%{} = args) do
    filters = %{}
    filters = if Map.has_key?(args, :scenario_set_id), do: Map.put(filters, :id, args.scenario_set_id), else: filters
    filters
  end

  @doc """
  batch loads all ScenarioDisplays in a Decision, then matches to specified record
  """
  def batch_load_scenario_displays(parent, modifiers, _resolution) do
    modifiers = Map.put(modifiers, :scenario_id, parent.id)
    resolver = {Scenarios, :match_scenario_displays, modifiers}
    batch_has_many(parent, :scenario_displays, :scenario_id, resolver)
  end

  @doc """
  loads all Options then filters them by parent
  """
  def batch_load_options(parent, modifiers, _resolution) do
    modifiers = Map.put(modifiers, :decision_id, parent.decision_id)
    resolver = {Structure, :match_options, modifiers}
    batch_many_to_many(parent, :options, :scenarios, resolver)
  end

end
