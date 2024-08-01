defmodule EtheloApi.Graphql.Resolvers.Decision do
  @moduledoc """
  Resolvers for graphql.
  Because Decision is always a root object, we use the 2 arity resolver calls.
  """

  alias EtheloApi.Helpers.EctoHelper
  alias EtheloApi.Import
  alias EtheloApi.Import.ImportProcess
  alias EtheloApi.Invocation
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision

  import EtheloApi.Helpers.ValidationHelper

  @doc """
  lists all Decisions

  See `EtheloApi.Structure.list_decisions/0` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """

  def list(params, _resolution) do
    params
    |> Structure.list_decisions()
    |> success()
  end

  @doc """
  lists all Decisions matching modifiers

  See `EtheloApi.Structure.list_decisions/1` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """

  def match_decision(params, _resolution) do
    decision = params |> extract_filters() |> Structure.match_decision()

    case decision do
      nil ->
        {:ok, not_found_error(:filters)}

      %Decision{} ->
        %{decision: decision} |> success()
    end
  end

  def extract_filters(%{} = params) do
    modifiers = %{}

    modifiers =
      if Map.has_key?(params, :decision_id),
        do: Map.put(modifiers, :id, params.decision_id),
        else: modifiers

    modifiers =
      if Map.has_key?(params, :decision_slug),
        do: Map.put(modifiers, :slug, params.decision_slug),
        else: modifiers

    modifiers
  end

  @doc """
  creates a new Decision

  See `EtheloApi.Structure.create_decision/1` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def create(%{input: params}, _resolution) do
    case Structure.create_decision(params) do
      {:error, %Ecto.Changeset{} = changeset} -> success(changeset)
      {:ok, decision} -> success(decision)
      error -> error
    end
  end

  # @doc """
  # creates a Decision from a json export

  # See EtheloApi.Import.ImportProcess.build_from_json(/2` for more info
  # Results are wrapped in a result monad as expected by absinthe.
  # """
  def import(%{input: %{json_data: json_data} = params}, _resolution) do
    case Import.build_from_json(json_data, params) do
      {:ok, decision} ->
        {:ok, decision}

      {:error, %ImportProcess{} = process} ->
        {:error, Import.summarize_errors(process)}

      {:error, _} ->
        {:error, validation_message("Unexpected Error, Import Failed", :decision_id, :unknown)}
    end
  end

  # @doc """
  # creates a copy of a Decision

  # See `EtheloApi.Import.DecisionCopy.copy/4` for more info
  # Results are wrapped in a result monad as expected by absinthe.
  # """
  def copy(%{input: %{decision: decision} = params}, _resolution) do
    Import.copy_decision(decision, params)
  end

  @doc """
  updates a Decision.

  See `EtheloApi.Structure.update_decision/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def update(%{input: %{id: id} = params}, _resolution) do
    id = if is_binary(id), do: String.to_integer(id), else: id

    if EctoHelper.exists?(Decision, %{id: id}, [:id]) do
      Structure.update_decision(id, params)
    else
      {:error, not_found_error(:id)}
    end
  end

  @doc """
  updates Decision cache.
  """
  def update_cache(%{input: %{id: id}}, _resolution) do
    id = if is_binary(id), do: String.to_integer(id), else: id

    decision = Structure.get_decision(id)

    if is_nil(decision) do
      {:error, not_found_error(:id)}
    else
      Invocation.update_decision_cache(decision)
      {:ok, decision}
    end
  end

  @doc """
  deletes a Decision.

  See `EtheloApi.Structure.delete_decision/1` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(%{input: %{id: id}}, _resolution) when is_binary(id) do
    Structure.delete_decision(String.to_integer(id))
  end

  def delete(%{input: %{id: id}}, _resolution) do
    Structure.delete_decision(id)
  end

  @doc """
  return JSON dump for Decision
  """
  def solve_files(decision, params, _resolution) do
    Invocation.invocation_files(decision, params)
  end

  @doc """
  return whether or not the ScenarioConfig is present in cache
  """
  def config_cache_exists(decision, %{scenario_config_id: scenario_config_id}, _resolution) do
    {:ok, Invocation.scenario_config_cache_exists(scenario_config_id, decision)}
  end

  @doc """
  return whether or not the Decision is present in cache
  """
  def decision_cache_exists(decision, _params, _resolution) do
    {:ok, Invocation.decision_cache_exists(decision)}
  end

  # @doc """
  # exports Decision as JSON

  # See `EtheloApi.Import.ExportBuilder.export_decision/1` for more info
  # Results are wrapped in a result monad as expected by absinthe.
  # """
  def export(decision, _params, _resolution) do
    case Import.export_decision(decision) do
      {:ok, decision_export} ->
        {:ok, decision_export}

      {:error, _} ->
        {:error, validation_message("Unexpected Error, Unable to Export", :export, :export_error)}
    end
  end
end
