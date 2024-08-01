defmodule EtheloApi.Graphql.Schemas.ScenarioDisplay do
  @moduledoc """
  Base access to ScenarioDisplays
  """
  use DocsComposer, module: EtheloApi.Scenarios.Docs.ScenarioDisplay

  use Absinthe.Schema.Notation

  @desc @doc_map.strings.scenario_display
  object :scenario_display do
    @desc @doc_map.strings.id
    field :id, non_null(:id)
    @desc @doc_map.strings.calculation_id
    field :calculation_id, :id
    @desc @doc_map.strings.constraint_id
    field :constraint_id, :id
    @desc @doc_map.strings.name
    field :name, non_null(:string)
    @desc @doc_map.strings.value
    field :value, non_null(:float)
    @desc @doc_map.strings.is_constraint
    field :is_constraint, non_null(:boolean)
    @desc @doc_map.strings.inserted_at
    field :inserted_at, non_null(:datetime)
    @desc @doc_map.strings.updated_at
    field :updated_at, non_null(:datetime)
  end
end
