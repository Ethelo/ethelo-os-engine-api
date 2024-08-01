defmodule EtheloApi.Invocation.MockEngine do
  @moduledoc """
  The boundary for communicating with the EtheloApi.
  """

  # alias EtheloApi.Scenarios.Dispatcher

  @spec engine_solve({String.t(), String.t(), String.t(), String.t(), String.t() | nil}) ::
          {:ok, String.t()}
          | {:error, String.t()}
          | {:error, atom()}
          | {:error, {:error, String.t()}}
  @doc """
  triggers a solve call on the engine.
  It accepts a set of invocation files json files

  files:
  {decision_json, influents_json, weights_json, config_json, preprocess_content}

  See EtheloApi.Invocation.ScenarioSolve for error and response handling.
  """
  def engine_solve(_files) do
    {:ok, "solve"}

    #   ExRevol.call(:solve, files, options)
  end

  @spec engine_preprocessed(String.t() | nil) :: {:ok | :error, String.t()}
  @doc """
  generates the a preprocessed file for the decision.
  This allows the engine to skip duplicate steps and solve faster.
  It accepts a Decision json file generated by build_decision_json/2
  """
  def engine_preprocessed("") do
    {:error, "nothing to parse"}
  end

  def engine_preprocessed(_decision_json) do
    # ExRevol.call(:preproc, decision_json)
    {:ok, "prepoc"}
  end
end
