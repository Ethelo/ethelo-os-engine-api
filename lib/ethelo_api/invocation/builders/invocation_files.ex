defmodule EtheloApi.Invocation.InvocationFiles do
  @moduledoc """
  Content of json and other files passed to and from the engine
  """
  require Logger

  alias EtheloApi.Invocation
  alias EtheloApi.Invocation.InvocationFiles
  alias EtheloApi.Invocation.InvocationSettings
  alias EtheloApi.Invocation.ScoringData

  @enforce_keys [
    :decision_json,
    :config_json,
    :influents_json,
    :weights_json
  ]

  defstruct [
    :preprocessed,
    :decision_json,
    :config_json,
    :influents_json,
    :weights_json,
    :response_json,
    :hash
  ]

  @type t :: %__MODULE__{
          preprocessed: String.t() | nil,
          decision_json: String.t(),
          config_json: String.t(),
          influents_json: String.t(),
          weights_json: String.t(),
          response_json: String.t() | nil,
          hash: String.t() | nil
        }

  def create(%InvocationSettings{} = settings, %ScoringData{} = voting_data) do
    with(
      {:ok, decision_json} <- decision_json(settings),
      {:ok, config_json} <- config_json(settings, voting_data),
      {:ok, influents_json} <- influents_json(voting_data),
      {:ok, weights_json} <- weights_json(voting_data)
    ) do
      %InvocationFiles{
        preprocessed: preprocessed(settings),
        decision_json: decision_json,
        config_json: config_json,
        influents_json: influents_json,
        weights_json: weights_json
      }
      |> ok()
    end
  end

  defp decision_json(%{use_cache: true} = settings) do
    case Invocation.get_decision_cache_value(settings.decision_id) do
      nil -> {:error, "missing Decision cache"}
      decision_json -> {:ok, decision_json}
    end
  end

  defp decision_json(%{} = settings) do
    settings.decision_id
    |> ScoringData.initialize_decision_json_data()
    |> EtheloApi.Invocation.DecisionJson.build_json(false)
    |> ok()
  end

  defp preprocessed(%{use_cache: true} = settings) do
    {:ok, Invocation.get_decision_preprocessed_cache_value(settings.decision_id)}
  end

  defp preprocessed(_), do: {:ok, ""}

  defp config_json(%{use_cache: true} = settings, _voting_data) do
    case Invocation.get_scenario_config_cache_value(
           settings.scenario_config.id,
           settings.decision_id
         ) do
      nil -> {:error, "missing ScenarioConfig cache"}
      config_json -> {:ok, config_json}
    end
  end

  defp config_json(%{} = settings, voting_data) do
    settings.scenario_config
    |> EtheloApi.Invocation.ConfigJson.build(voting_data.option_categories)
    |> EtheloApi.Invocation.ConfigJson.to_json()
    |> ok()
  end

  defp influents_json(%{} = voting_data) do
    influents_json =
      voting_data
      |> EtheloApi.Invocation.InfluentsJson.build()
      |> EtheloApi.Invocation.InfluentsJson.to_json()

    if influents_json == "[]" do
      {:error, "no votes"}
    else
      {:ok, influents_json}
    end
  end

  defp weights_json(%{} = voting_data) do
    voting_data
    |> EtheloApi.Invocation.WeightsJson.build()
    |> EtheloApi.Invocation.WeightsJson.to_json()
    |> ok()
  end

  defp ok(response), do: {:ok, response}
end
