defmodule Engine.Invocation.ScenarioHashes do
  @moduledoc """
  Registry of data associated with an engine invocation
  """
  alias Engine.Invocation
  alias Engine.Scenarios
  alias Engine.Scenarios.ScenarioConfig
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Voting
  alias EtheloApi.Voting.Participant
  alias EtheloApi.Voting.CriteriaWeight
  alias EtheloApi.Voting.BinVote
  alias EtheloApi.Voting.OptionCategoryRangeVote
  alias EtheloApi.Voting.OptionCategoryWeight

  import Ecto.Query, warn: false
  alias EtheloApi.Repo

  require Logger
  require OK

  defp cached_or_live_parts(decision, scenario_config, use_cached_decision) do
    if use_cached_decision do
      {
        Map.get(decision, :published_decision_hash),
        Map.get(scenario_config, :published_engine_hash)
      }
    else
      {
        Map.get(decision, :preview_decision_hash),
        Map.get(scenario_config, :preview_engine_hash)
      }
    end
  end

  def get_group_scenario_hash(%Decision{} = decision, scenario_config, use_cached_decision) do
    {structure_part, config_part} =
      cached_or_live_parts(decision, scenario_config, use_cached_decision)

    structure_part =
      if is_nil(structure_part) do
        ""
      else
        structure_part
      end

    [
      to_string(structure_part),
      to_string(config_part),
      to_string(Map.get(decision, :influent_hash)),
      to_string(Map.get(decision, :weighting_hash))
    ]
    |> Enum.join("-")
    |> OK.success()
  end

  def get_participant_scenario_hash(
        %Decision{} = decision,
        scenario_config,
        use_cached_decision,
        %Participant{} = participant
      ) do
    {structure_part, config_part} =
      cached_or_live_parts(decision, scenario_config, use_cached_decision)

    structure_part =
      if is_nil(structure_part) do
        ""
      else
        structure_part
      end

    [
      to_string(structure_part),
      to_string(config_part),
      to_string(Map.get(participant, :influent_hash))
    ]
    |> Enum.join("-")
    |> OK.success()
  end

  defp hash_from_string(nil), do: nil
  defp hash_from_string(""), do: ""

  defp hash_from_string(string) do
    :crypto.hash(:md5, [string]) |> Base.encode16()
  end

  def generate_decision_hash(decision_id, use_cached_decision \\ false)

  def generate_decision_hash(%Decision{id: decision_id}, use_cached_decision),
    do: generate_decision_hash(decision_id, use_cached_decision)

  def generate_decision_hash(decision_id, true), do: get_cached_decision_hash(decision_id)

  def generate_decision_hash(decision_id, _) do
    decision_json = Invocation.build_decision_json(decision_id, false)
    {:ok, hash_from_string(decision_json)}
  end

  def get_cached_decision_hash(decision_id) do
    case Invocation.get_decision_cache_value(decision_id) do
      nil -> {:error, "missing decision cache"}
      cached_value -> {:ok, cached_value |> hash_from_string}
    end
  end

  def generate_scenario_config_hash(decision_id, scenario_config, use_cached_decision \\ false)

  def generate_scenario_config_hash(decision_id, %ScenarioConfig{} = scenario_config, true) do
    get_cached_scenario_config_hash(decision_id, scenario_config.id)
  end

  def generate_scenario_config_hash(decision_id, %ScenarioConfig{} = scenario_config, _) do
    config_json = Invocation.build_config_json(scenario_config, decision_id, false)
    {:ok, hash_from_string(config_json)}
  end

  def generate_scenario_config_hash(decision_id, scenario_config_id, use_cached_decision) do
    scenario_config = Scenarios.get_scenario_config(decision_id, scenario_config_id)
    generate_scenario_config_hash(decision_id, scenario_config, use_cached_decision)
  end

  def get_cached_scenario_config_hash(decision_id, scenario_config_id) do
    case Invocation.get_scenario_config_cache_value(scenario_config_id, decision_id) do
      nil -> {:error, "missing scenario config cache"}
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
      max -> inspect(max)
    end
  end

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
    |> OK.success()
  end

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
    |> OK.success()
  end

  def generate_weighting_hash(decision_id, participant \\ nil)

  def generate_weighting_hash(_, %Participant{} = participant) do
    generate_participant_influent_hash(participant)
  end

  def generate_weighting_hash(decision_id, nil) do
    generate_group_influent_hash(decision_id)
  end

  def generate_weighting_hash(decision_id, participant_id) do
    case Voting.get_participant(participant_id, decision_id) do
      nil -> {:error, "missing participant"}
      participant -> generate_weighting_hash(decision_id, participant)
    end
  end
end
