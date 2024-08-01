defmodule EtheloApi.Graphql.Resolvers.ScenarioSet do
  @moduledoc """
  Resolvers for graphql.
  """

  alias AbsintheErrorPayload.ValidationMessage
  alias EtheloApi.Scenarios
  alias EtheloApi.Invocation
  alias EtheloApi.Structure.Decision
  import EtheloApi.Helpers.ValidationHelper

  @doc """
  lists all ScenarioSets in a Decision

  See `EtheloApi.ScenarioSet.list_scenario_sets/1` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    latest = Map.get(modifiers, :latest, false)
    modifiers = Map.delete(modifiers, :latest)

    if latest do
      [decision |> Scenarios.match_latest_scenario_set(modifiers)] |> success()
    else
      decision |> Scenarios.list_scenario_sets(modifiers) |> success()
    end
  end

  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  triggers an Engine Call to solve a Decision creating a ScenarioSet as a result

  See `EtheloApi.Invocation.solve/3` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def solve(%{input: %{decision: decision} = input}, _resolution) do
    case Invocation.queue_solve(decision, input) do
      {:error, %ValidationMessage{} = message} ->
        {:error, message}

      {:error, error} ->
        message = %ValidationMessage{
          field: :unknown,
          code: :unknown,
          message: error,
          template: error
        }

        {:error, message}

      {:ok, _} ->
        {:ok, nil}
    end
  end
end
