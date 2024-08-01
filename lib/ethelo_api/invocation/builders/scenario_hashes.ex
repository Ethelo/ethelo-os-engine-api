defmodule EtheloApi.Invocation.ScenarioHashes do
  @moduledoc """
  Generates the unique hashes that are used to identify
  a unique Decision state.
  Cached Values represent a 'published' state that does not
  reflect ongoing changes, and are most commonly used.
  Non cached values are built fresh and are more intensive.

  The hash values are used when trigging solves to
  identify if there is a new solve needed.
  Change to the structure, ScenarioConfig or voting all require fresh solves
  However, we use timestamps for efficiency instead of generating the entire
  invocation json.

  Changes to Structure and Voting will trigger updates.
  """
  require Logger

  alias EtheloApi.Repo
  alias EtheloApi.Invocation
  alias EtheloApi.Structure
  alias EtheloApi.Structure.ScenarioConfig
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Voting.Participant
  alias EtheloApi.Voting.CriteriaWeight
  alias EtheloApi.Voting.BinVote
  alias EtheloApi.Voting.OptionCategoryRangeVote
  alias EtheloApi.Voting.OptionCategoryWeight

  import Ecto.Query, warn: false

  defp get_structure_part(decision, true) do
    Map.get(decision, :published_decision_hash, "")
  end

  defp get_structure_part(decision, _) do
    Map.get(decision, :preview_decision_hash, "")
  end

  defp get_config_part(scenario_config, true) do
    Map.get(scenario_config, :published_engine_hash, "")
  end

  defp get_config_part(scenario_config, _) do
    Map.get(scenario_config, :preview_engine_hash, "")
  end

  @spec get_group_scenario_hash(EtheloApi.Structure.Decision.t(), map(), boolean()) ::
          {:ok, String.t()}
  @doc """
  builds a hash that encodes the current status of the decision,
  including the current structure,ScenarioConfig and voting/weighting
  Usually the cached Decision data is used, but disabling "use_cache" generates fresh copies
  """
  def get_group_scenario_hash(%Decision{} = decision, scenario_config, use_cache) do
    structure_part = get_structure_part(decision, use_cache)
    config_part = get_config_part(scenario_config, use_cache)

    [
      to_string(structure_part),
      to_string(config_part),
      to_string(Map.get(decision, :influent_hash))
    ]
    |> Enum.join("-")
    |> ok()
  end

  @spec get_participant_scenario_hash(
          struct(),
          map(),
          boolean(),
          struct()
        ) :: {:ok, any}

  @doc """
  builds a hash that encodes the current status of the Decision,
  but only for one Participant
  the current structure and ScenarioConfigs are identical for Participants
  but the voting/weighting segments only include the individual Participants activity
  Usually the cached Decision data is used, but a 'preview' mode generates fresh copies
  """
  def get_participant_scenario_hash(
        %Decision{} = decision,
        scenario_config,
        use_cache,
        %Participant{} = participant
      ) do
    structure_part = get_structure_part(decision, use_cache)
    config_part = get_config_part(scenario_config, use_cache)

    [
      to_string(structure_part),
      to_string(config_part),
      to_string(Map.get(participant, :influent_hash))
    ]
    |> Enum.join("-")
    |> ok()
  end

  defp hash_from_string(nil), do: nil
  defp hash_from_string(""), do: ""

  defp hash_from_string(string) do
    :crypto.hash(:md5, [string]) |> Base.encode16()
  end

  @spec generate_scenario_config_hash(
          nil | integer,
          integer | struct,
          boolean()
        ) :: {:ok, nil | String.t()}
  @doc """
  Build a hash to represent the curret state of the ScenarioConfig settings
  by generating the structure to be sent to the engine
  and then creating a hash from that.

  This ensures that changes not sent to the engine do not
  affect the hash value

  This includes changes to the ScenarioConfig models, and also changes to
  the list of OptionCategories as they are sent in with this file.
  """
  def generate_scenario_config_hash(decision_id, scenario_config, use_cache \\ false)

  def generate_scenario_config_hash(decision_id, %ScenarioConfig{id: scenario_config_id}, true) do
    get_cached_scenario_config_hash(decision_id, scenario_config_id)
  end

  def generate_scenario_config_hash(decision_id, %ScenarioConfig{} = scenario_config, _) do
    config_json = Invocation.build_config_json(scenario_config, decision_id, false)
    {:ok, hash_from_string(config_json)}
  end

  def generate_scenario_config_hash(decision_id, scenario_config_id, use_cache) do
    scenario_config = Structure.get_scenario_config(decision_id, scenario_config_id)
    generate_scenario_config_hash(decision_id, scenario_config, use_cache)
  end

  @spec get_cached_scenario_config_hash(integer() | struct(), integer() | nil) ::
          {:error, String.t()} | {:ok, nil | String.t()}
  defp get_cached_scenario_config_hash(decision_id, scenario_config_id) do
    case Invocation.get_scenario_config_cache_value(scenario_config_id, decision_id) do
      nil -> {:error, "missing ScenarioConfig cache"}
      cached_value -> {:ok, hash_from_string(cached_value)}
    end
  end

  defp max_date_for(schema, decision_id) do
    max_date_for(schema, decision_id, nil)
  end

  defp max_date_for(schema, decision_id, participant_id) do
    query =
      schema
      |> where([s], s.decision_id == ^decision_id)
      |> select([s], max(s.updated_at))

    query =
      if is_nil(participant_id) do
        query
      else
        query |> where([s], s.participant_id == ^participant_id)
      end

    query
    |> Repo.one()
    |> case do
      nil -> ""
      max -> DateTime.to_iso8601(max)
    end
  end

  @spec generate_group_influent_hash(integer() | struct()) :: {:ok, String.t()}
  @doc """
  Build a hash to represent the curret state of votes and weights
  submitted by Participants. Because this can be a large volumn of data
  the latest update date for each type of record is loaded to use for the hash

  Originally Influent (voting) and Weighting changes
  were hashed separately, but they are combined as there is no
  advantage to tracking them separately - when a new influent hash is
  generated, a new weighting hash is always also generated

  """
  def generate_group_influent_hash(%Decision{id: decision_id}) do
    generate_group_influent_hash(decision_id)
  end

  def generate_group_influent_hash(decision_id) do
    [
      max_date_for(BinVote, decision_id),
      max_date_for(OptionCategoryWeight, decision_id),
      max_date_for(OptionCategoryRangeVote, decision_id),
      max_date_for(CriteriaWeight, decision_id)
    ]
    |> Enum.max()
    |> hash_from_string
    |> ok()
  end

  @spec generate_participant_influent_hash(struct()) :: {:ok, String.t()}
  @doc """
  Build a hash to represent the curret state of votes and weights
  submitted by a single Participants Because this can be a large volumn of data
  the latest update date for each type of record is loaded to use for the hash

  Originally Influent (voting) and Weighting changes
  were hashed separately, but they are combined as there is no
  advantage to tracking them separately - when a new influent hash is
  generated, a new weighting hash is always also generated

  """
  def generate_participant_influent_hash(%Participant{
        decision_id: decision_id,
        id: participant_id
      }) do
    [
      max_date_for(BinVote, decision_id, participant_id),
      max_date_for(OptionCategoryWeight, decision_id, participant_id),
      max_date_for(OptionCategoryRangeVote, decision_id, participant_id),
      max_date_for(CriteriaWeight, decision_id, participant_id)
    ]
    |> Enum.max()
    |> hash_from_string
    |> ok()
  end

  defp ok(response), do: {:ok, response}
end
