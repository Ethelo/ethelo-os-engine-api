defmodule EtheloApi.Invocation.InvocationSettings do
  @moduledoc """
  Registry of data associated with an engine invocation
  """

  require Logger
  import EtheloApi.Helpers.ValidationHelper

  alias EtheloApi.Helpers.EctoHelper
  alias EtheloApi.Invocation
  alias EtheloApi.Invocation.InvocationSettings
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Voting
  alias EtheloApi.Voting.BinVote
  alias EtheloApi.Voting.OptionCategoryBinVote
  alias EtheloApi.Voting.OptionCategoryRangeVote

  @enforce_keys [
    :decision_id,
    :scenario_config_id,
    :use_cache
  ]

  defstruct [
    :decision_id,
    :decision,
    :scenario_config,
    :scenario_config_id,
    :use_cache,
    :force,
    :participant,
    :participant_id,
    :save_dump
  ]

  @type t :: %__MODULE__{
          decision_id: integer(),
          decision: struct() | nil,
          scenario_config_id: integer(),
          scenario_config: struct() | nil,
          participant_id: integer() | nil,
          participant: struct() | nil,
          use_cache: boolean(),
          save_dump: boolean(),
          force: boolean()
        }

  @spec build(integer | struct(), integer(), keyword()) ::
          {:error, String.t()}
          | {:ok, EtheloApi.Invocation.InvocationSettings.t()}
  def build(decision_id, scenario_config_id, options \\ []) do
    %InvocationSettings{
      decision_id: decision_id,
      force: Keyword.get(options, :force, false),
      participant_id: Keyword.get(options, :participant_id, nil),
      save_dump: Keyword.get(options, :save_dump, false),
      scenario_config_id: scenario_config_id,
      use_cache: Keyword.get(options, :use_cache, false)
    }
    |> load_records()
  end

  @doc """
  Process options to ensure defaults are properly set.

  depending on the caller, keys may be a Keyword list,
  a string keyed Map or an atom keyed Map
  """
  def process_options(args) when is_list(args) do
    [
      force: Keyword.get(args, :force, false),
      participant_id: Keyword.get(args, :participant_id, nil),
      save_dump: Keyword.get(args, :save_dump, false),
      scenario_config_id: Keyword.get(args, :scenario_config_id, nil),
      use_cache: Keyword.get(args, :use_cache, false)
    ]
  end

  def process_options(args) when is_map(args) do
    with_string_keys = for {k, v} <- args, do: {to_string(k), v}, into: %{}

    [
      force: Map.get(with_string_keys, "force", false),
      participant_id: Map.get(with_string_keys, "participant_id", nil),
      save_dump: Map.get(with_string_keys, "save_dump", nil),
      scenario_config_id: Map.get(with_string_keys, "scenario_config_id", nil),
      use_cache: Map.get(with_string_keys, "use_cache", false)
    ]
  end

  defp load_records(%InvocationSettings{} = base_settings) do
    with(
      {:ok, decision} <- get_decision(base_settings.decision_id),
      {:ok, scenario_config} <-
        get_scenario_config(base_settings.decision_id, base_settings.scenario_config_id),
      {:ok, participant} <-
        get_participant(base_settings.decision_id, base_settings.participant_id),
      {:ok, _} <-
        verify_caches(base_settings, base_settings.decision_id, base_settings.scenario_config_id)
    ) do
      participant_id = if is_nil(participant), do: nil, else: participant.id

      settings =
        Map.merge(base_settings, %{
          decision: decision,
          scenario_config: scenario_config,
          participant: participant,
          participant_id: participant_id
        })

      {:ok, settings}
    end
  end

  defp get_decision(decision_id) do
    case Structure.get_decision(decision_id) do
      %Decision{} = decision ->
        {:ok, decision}

      nil ->
        {:error, not_found_error(:decision_id)}
    end
  end

  defp get_participant(_, nil), do: {:ok, nil}

  defp get_participant(decision_id, participant_id) do
    case Voting.get_participant(participant_id, decision_id) do
      nil -> {:error, not_found_error(:participant_id)}
      participant -> {:ok, participant}
    end
  end

  defp get_scenario_config(_, nil) do
    {:error, validation_message("cannot be blank", :scenario_config_id, :required)}
  end

  defp get_scenario_config(decision_id, scenario_config_id) do
    case Structure.get_scenario_config(scenario_config_id, decision_id) do
      nil -> {:error, not_found_error(:scenario_config_id)}
      scenario_config -> {:ok, scenario_config}
    end
  end

  defp verify_caches(%{use_cache: false}, _, _), do: {:ok, true}

  defp verify_caches(_, decision_id, scenario_config_id) do
    {
      Invocation.decision_cache_exists(decision_id),
      Invocation.scenario_config_cache_exists(scenario_config_id, decision_id)
    }
    |> case do
      {true, true} ->
        {:ok, true}

      {false, _} ->
        {:error, validation_message("Decision cache does not exist", :use_cache, :not_found)}

      {_, false} ->
        {:error,
         validation_message("ScenarioConfig cache does not exist", :use_cache, :not_found)}
    end
  end

  def verify_votes(_, false) do
    {:ok, true}
  end

  def verify_votes(%{decision_id: decision_id, participant_id: nil}, _) do
    verify_votes(%{decision_id: decision_id})
  end

  def verify_votes(%{decision_id: decision_id, participant_id: participant_id}, _) do
    verify_votes(%{decision_id: decision_id, participant_id: participant_id})
  end

  def verify_votes(filter) do
    allowed = [:decision_id, :participant_id]

    votes = [
      EctoHelper.exists?(BinVote, filter, allowed),
      EctoHelper.exists?(OptionCategoryBinVote, filter, allowed),
      EctoHelper.exists?(OptionCategoryRangeVote, filter, allowed)
    ]

    if Enum.any?(votes) do
      {:ok, true}
    else
      {:error, validation_message("must have votes", :decision_id, :votes)}
    end
  end
end
