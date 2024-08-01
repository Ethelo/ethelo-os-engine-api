defmodule GraphQL.EtheloApi.Resolvers.Decision do
  @moduledoc """
  Resolvers for graphql.
  Because decision is always a root object, we use the 2 arity resolver calls.
  """

  alias Engine.Invocation
  alias EtheloApi.Voting
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  alias Engine.Scenarios.ScenarioConfig
  alias EtheloApi.Serialization.DecisionCopy
  alias EtheloApi.Serialization.DecisionExport
  alias EtheloApi.Serialization.DecisionImport
  alias EtheloApi.Serialization.Import.ImportError
  alias Kronky.ValidationMessage
  import GraphQL.EtheloApi.ResolveHelper

  @doc """
  lists all decisions

  See `EtheloApi.Structure.list_decisions/0` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def list(args, _resolution) do
    args
    |> Structure.list_decisions()
    |> success()
  end

  @doc """
  lists all decisions

  See `EtheloApi.Structure.list_decisions/1` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def match_decision(args, _resolution) do
    decision = args |> extract_filters() |> Structure.match_decision()

    case decision do
      nil -> {:ok, %ValidationMessage{field: :filters, code: :not_found, message: "does not exist", template: "does not exist"}}
      %Decision{} -> %{decision: decision} |> success()
    end
  end

  def extract_filters(%{} = args) do
    filters = %{}
    filters = if Map.has_key?(args, :decision_id), do: Map.put(filters, :id, args.decision_id), else: filters
    filters = if Map.has_key?(args, :decision_slug), do: Map.put(filters, :slug, args.decision_slug), else: filters
    filters
  end

  @doc """
  gets a Decision by id

  See `EtheloApi.Structure.get_decision/1` for more info
  Results are wrapped in a result monad as expected by absinthe.

  """
  def get(attrs, _resolution), do: verify_decision(attrs)

  @doc """
  return JSON dump decision
  """
  def dump_json(decision, attrs, _resolution) do
    scenario_config_id = Map.get(attrs, :scenario_config_id) |> sanitize_id
    participant_id = Map.get(attrs, :participant_id) |> sanitize_id
    case verify_ids([{ScenarioConfig, :scenario_config_id, scenario_config_id},
                     {Voting.Participant, :participant_id, participant_id}], decision.id) do
      :ok ->
        case Invocation.invocation_jsons(
               decision,
               scenario_config_id: scenario_config_id,
               participant_id: participant_id,
               cached: Map.get(attrs, :cached, false)
             ) do
          {:error, {type, error}} when is_atom(type) -> {:error, "#{type}: #{error}"}
          {:error, error} -> {:ok, "#{error}"}
          {:ok, result} -> {:ok, result}
        end

      {:error, message} ->
        {:error, "#{inspect(message)}"}
    end
  end

  @doc """
  return whether or not the scenario config is present in cache
  """
  def config_cache_exists(decision, %{scenario_config_id: scenario_config_id}, _resolution) do
    case Invocation.get_scenario_config_cache_value(scenario_config_id, decision) do
      nil -> {:ok, false}
      _ -> {:ok, true}
    end
  end

  @doc """
  return whether or not the decision is present in cache
  """
  def decision_cache_exists(decision, _params, _resolution) do
    case Invocation.get_decision_cache_value(decision) do
      nil -> {:ok, false}
      _ -> {:ok, true}
    end
  end

  @doc """
  return a votes date histogram
  """
  def votes_histogram(decision, %{type: type}, _resolution) when is_binary(type) do
    {:ok, Voting.bin_votes_histogram(decision, type)}
  end

  def votes_histogram(decision, _params, _resolution) do
    {:ok, Voting.bin_votes_histogram(decision)}
  end

  @doc """
  creates a new decision

  See `EtheloApi.Structure.create_decision/1` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def create(%{input: attrs}, _resolution) do
    case Structure.create_decision(attrs) do
      {:error, %Ecto.Changeset{} = changeset} -> success(changeset)
      {:ok, decision} -> success(decision)
      error -> error
    end
  end

  @doc """
  updates an existing decision.

  See `EtheloApi.Structure.update_decision/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def update(decision, input) do
    Structure.update_decision(Map.get(decision, :id), input)
  end

  @doc """
  updates decision cache.
  """
  def cache(decision, _input) do
    Invocation.update_decision_cache(Map.get(decision, :id))
  end

  @doc """
  exports decision as JSON using DecisionExport

  See `EtheloApi.Serialization.DecisionExport.export/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def export(decision, attrs, _resolution) do
    case DecisionExport.export(decision, pretty: Map.get(attrs, :pretty, false)) do
      {:ok, decision_export} ->
        {:ok, decision_export}

      {:error, reason} ->
        {:ok, %ValidationMessage{code: :export_error, message: "#{inspect reason}", template: "export error"}}
    end
  end

  @doc """
  creates a decision from a json export

  See `EtheloApi.Serialization.DecisionImport.import/2` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def import(%{input: %{export: export} = attrs}, _resolution) do
    case DecisionImport.import(export, title: Map.get(attrs, :title),
                                       slug: Map.get(attrs, :slug),
                                       info: Map.get(attrs, :info)) do
      {:ok, decision} ->
        {:ok, decision}

      {:error, %ImportError{reason: :duplicate_slug}} ->
        {:ok, %ValidationMessage{code: :import_error, message: "duplicate decision slug", template: "import error", field: :slug}}

      {:error, %ImportError{} = import_error} ->
        {:ok, %ValidationMessage{code: :import_error, message: ImportError.to_string(import_error), template: "import error", field: :export}}

      {:error, reason} ->
        {:ok, %ValidationMessage{code: :import_error, message: "#{inspect reason}", template: "import error", field: :export}}
    end
  end

  @doc """
  creates a copy of an existing decision

  See `EtheloApi.Serialization.DecisionCopy.copy/4` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def copy(decision, input) do
    case DecisionCopy.copy(decision, title: Map.get(input, :title),
                                     slug: Map.get(input, :slug),
                                     info: Map.get(input, :info)) do
      {:ok, decision} ->
        {:ok, decision}

      {:error, %ImportError{reason: :duplicate_slug}} ->
        {:ok, %ValidationMessage{code: :import_error, message: "duplicate slug", template: "import error", field: :slug}}

      {:error, %ImportError{} = import_error} ->
        {:ok, %ValidationMessage{code: :import_error, message: ImportError.to_string(import_error), template: "import error"}}

      {:error, reason} ->
        {:ok, %ValidationMessage{code: :copy_error, message: "#{inspect reason}", template: "copy error"}}
    end
  end

  @doc """
  updates an existing decision.

  See `EtheloApi.Structure.delete_decision/1` for more info
  Results are wrapped in a result monad as expected by absinthe.
  """
  def delete(_, %{id: id}) when is_binary(id) do
    Structure.delete_decision(String.to_integer(id))
  end
  def delete(_, %{id: id}) do
    Structure.delete_decision(id)
  end
end
