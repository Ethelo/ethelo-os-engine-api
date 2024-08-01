defmodule GraphQL.EtheloApi.AdminSchema.SolveDump do
  @moduledoc """
  Base access to decisions
  """
  use DocsComposer, module: Engine.Scenarios.Docs.SolveDump

  use Absinthe.Schema.Notation
  alias GraphQL.EtheloApi.Resolvers.SolveDump, as: SolveDumpResolver

  object :solve_dump, description: @doc_map.strings.solve_dump do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :scenario_set_id, :id, description: @doc_map.strings.scenario_set_id
    field :participant_id, :id, description: @doc_map.strings.participant_id
    field :decision_json, :string, description: @doc_map.strings.decision_json
    field :influents_json, :string, description: @doc_map.strings.influents_json
    field :weights_json, :string, description: @doc_map.strings.weights_json
    field :config_json, :string, description: @doc_map.strings.config_json
    field :response_json, :string, description: @doc_map.strings.response_json
    field :error, :string, description: @doc_map.strings.error
    field :inserted_at, non_null(:datetime), description: @doc_map.strings.inserted_at
    field :updated_at, non_null(:datetime), description: @doc_map.strings.updated_at
  end

  object :solve_dump_list do
    field :solve_dumps, list_of(:solve_dump) do
      arg :id, :id, description: "Filter by SolveDump id"
      arg :scenario_set_id, :id, description: "Filter by ScenarioSet id"
      arg :participant_id, :id, description: "Filter by Participant id"
      arg :latest, :boolean, description: "Return only the latest SolveDump"
    resolve &SolveDumpResolver.list/3
    end
  end

end
