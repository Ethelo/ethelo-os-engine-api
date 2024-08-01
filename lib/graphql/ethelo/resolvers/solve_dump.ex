defmodule GraphQL.EtheloApi.Resolvers.SolveDump do
  @moduledoc """
  Resolvers for graphql.
  """

  alias Engine.Scenarios
  alias Engine.Scenarios.SolveDump
  alias EtheloApi.Structure.Decision
  alias Kronky.ValidationMessage
  import GraphQL.EtheloApi.ResolveHelper
  import GraphQL.EtheloApi.BatchHelper

  @doc """
  lists all solve_dumps in a decision

  See `EtheloApi.SolveDump.list_solve_dumps/1` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def list(%{decision: %Decision{} = decision}, modifiers, _resolution) do
    latest = Map.get(modifiers, :latest, false)
    modifiers = Map.delete(modifiers, :latest)

    if latest do
      [decision |> Scenarios.get_latest_solve_dump(modifiers)] |> success()
    else
      decision |> Scenarios.list_solve_dumps(modifiers) |> success()
    end
  end
  def list(_, _, _resolution), do: {:ok, []}

  @doc """
  lists all solve_dumps in a decision

  See `EtheloApi.Structure.list_solve_dumps/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def match_solve_dump(args = %{decision: %Decision{} = decision}, _resolution) do
    solve_dump = args |> extract_filters() |> Scenarios.match_solve_dumps(decision)

    case solve_dump do
      nil -> {:ok, %ValidationMessage{field: :filters, code: :not_found, message: "does not exist", template: "does not exist"}}
      %SolveDump{} -> %{solve_dump: solve_dump} |> success()
    end
  end

  @doc """
  batch loads all SolveDumps for the Decision, then filters to match the specified record
  """
  def batch_solve_dumps(parent, modifiers, _resolution) do
    modifiers = Map.put(modifiers, :scenario_set_id, parent.id)
    resolver = {Structure, :match_solve_dumps, modifiers}
    batch_has_many(parent, :solve_dump, :scenario_set_id, resolver)
  end

  def extract_filters(%{} = args) do
    filters = %{}
    filters = if Map.has_key?(args, :solve_dump_id), do: Map.put(filters, :id, args.solve_dump_id |> sanitize_id), else: filters
    filters
  end

end
