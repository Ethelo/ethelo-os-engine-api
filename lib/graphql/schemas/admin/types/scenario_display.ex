defmodule GraphQL.EtheloApi.AdminSchema.ScenarioDisplay do
  @moduledoc """
  Base access to decisions
  """
  use DocsComposer, module: Engine.Scenarios.Docs.ScenarioDisplay

  use Absinthe.Schema.Notation

  object :scenario_display, description: @doc_map.strings.scenario_display do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :calculation_id, :id, description: @doc_map.strings.calculation_id
    field :constraint_id, :id, description: @doc_map.strings.constraint_id
    field :name, non_null(:string), description: @doc_map.strings.name
    field :value, non_null(:float), description: @doc_map.strings.value
    field :is_constraint, non_null(:boolean), description: @doc_map.strings.is_constraint
    field :inserted_at, non_null(:datetime), description: @doc_map.strings.inserted_at
    field :updated_at, non_null(:datetime), description: @doc_map.strings.updated_at
  end
end
