defmodule EtheloApi.Graphql.Schemas.SolveDump do
  @moduledoc """
  Base access to SolveDumps
  """

  use Absinthe.Schema.Notation
  use DocsComposer, module: EtheloApi.Scenarios.Docs.SolveDump
  import Absinthe.Resolution.Helpers, only: [dataloader: 2]

  @desc @doc_map.strings.solve_dump
  object :solve_dump do
    @desc @doc_map.strings.config_json
    field :config_json, :string

    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)

    @desc @doc_map.strings.decision_json
    field :decision_json, :string

    @desc @doc_map.strings.error
    field :error, :string

    @desc @doc_map.strings.id
    field :id, non_null(:id)

    @desc @doc_map.strings.influents_json
    field :influents_json, :string

    @desc @doc_map.strings.inserted_at
    field :inserted_at, non_null(:datetime)

    @desc @doc_map.strings.participant_id
    field :participant_id, :id

    @desc @doc_map.strings.participant_id
    field :participant, :participant, resolve: dataloader(:repo, :participant)

    @desc @doc_map.strings.response_json
    field :response_json, :string

    @desc @doc_map.strings.scenario_set_id
    field :scenario_set_id, :id

    @desc @doc_map.strings.scenario_set_id
    field :scenario_set, :scenario_set, resolve: dataloader(:repo, :scenario_set)

    @desc @doc_map.strings.updated_at
    field :updated_at, non_null(:datetime)

    @desc @doc_map.strings.weights_json
    field :weights_json, :string
  end
end
