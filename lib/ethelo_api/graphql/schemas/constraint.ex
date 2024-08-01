defmodule EtheloApi.Graphql.Schemas.Constraint do
  @moduledoc """
  Base access to Constraints
  """

  use Absinthe.Schema.Notation
  use DocsComposer, module: EtheloApi.Structure.Docs.Constraint
  alias EtheloApi.Graphql.Docs.Constraint, as: ConstraintDocs

  alias EtheloApi.Graphql.Resolvers.Constraint, as: ConstraintResolver

  import AbsintheErrorPayload.Payload

  import EtheloApi.Graphql.Middleware
  import Absinthe.Resolution.Helpers, only: [dataloader: 2]

  # hard coding so we can apply descriptions properly.
  enum :constraint_operators do
    @desc @doc_map.strings.operator_between
    value(:between)

    @desc @doc_map.strings.operator_equal_to
    value(:equal_to)

    @desc @doc_map.strings.operator_greater_than_or_equal_to
    value(:greater_than_or_equal_to)

    @desc @doc_map.strings.operator_less_than_or_equal_to
    value(:less_than_or_equal_to)
  end

  # queries
  object :constraint do
    @desc @doc_map.strings.calculation
    field :calculation, :calculation, resolve: dataloader(:repo, :calculation)

    @desc @doc_map.strings.calculation
    field :calculation_id, :id

    @desc @doc_map.strings.enabled
    field :enabled, :boolean

    @desc @doc_map.strings.id
    field :id, non_null(:id)

    @desc @doc_map.strings.inserted_at
    field :inserted_at, non_null(:datetime)

    @desc @doc_map.strings.lhs
    field :lhs, :float

    @desc @doc_map.strings.operator
    field :operator, non_null(:constraint_operators)

    @desc @doc_map.strings.option_filter
    field :option_filter, non_null(:option_filter), resolve: dataloader(:repo, :option_filter)

    @desc @doc_map.strings.option_filter
    field :option_filter_id, :id

    @desc @doc_map.strings.relaxable
    field :relaxable, :boolean

    @desc @doc_map.strings.rhs
    field :rhs, :float

    @desc @doc_map.strings.slug
    field :slug, non_null(:string)

    @desc @doc_map.strings.title
    field :title, non_null(:string)

    @desc @doc_map.strings.updated_at
    field :updated_at, non_null(:datetime)

    @desc @doc_map.strings.variable
    field :variable, :variable, resolve: dataloader(:repo, :variable)

    @desc @doc_map.strings.variable
    field :variable_id, :id
  end

  object :constraint_list do
    field :constraints, list_of(:constraint) do
      @desc @doc_map.strings.calculation_id
      arg(:calculation_id, :id)

      @desc @doc_map.strings.enabled
      arg(:enabled, :boolean)

      @desc "Filter by Constraint id"
      arg(:id, :id)

      @desc @doc_map.strings.option_filter_id
      arg(:option_filter_id, :id)

      @desc "Filter by Constraint slug"
      arg(:slug, :string)

      @desc @doc_map.strings.variable_id
      arg(:variable_id, :id)

      resolve(&ConstraintResolver.list/3)
    end
  end

  # mutations

  payload_object(:constraint_payload, :constraint)

  input_object :constraint_params do
    @desc @doc_map.strings.calculation_id
    field :calculation_id, :id

    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)

    @desc @doc_map.strings.enabled
    field :enabled, :boolean

    @desc @doc_map.strings.lhs
    field :lhs, :float

    @desc @doc_map.strings.operator
    field :operator, non_null(:constraint_operators)

    @desc @doc_map.strings.option_filter_id
    field :option_filter_id, :id

    @desc @doc_map.strings.relaxable
    field :relaxable, :boolean

    @desc @doc_map.strings.rhs
    field :rhs, :float

    @desc @doc_map.strings.slug
    field :slug, :string

    @desc @doc_map.strings.variable_id
    field :variable_id, :id
  end

  @desc ConstraintDocs.create()
  input_object :create_constraint_params do
    @desc @doc_map.strings.title
    field :title, non_null(:string)

    import_fields(:constraint_params)
  end

  @desc ConstraintDocs.update()
  input_object :update_constraint_params do
    @desc @doc_map.strings.id
    field :id, non_null(:id)

    @desc @doc_map.strings.title
    field :title, :string
    import_fields(:constraint_params)
  end

  @desc ConstraintDocs.delete()
  input_object :delete_constraint_params do
    @desc @doc_map.strings.decision_id
    field :decision_id, non_null(:id)

    @desc @doc_map.strings.id
    field :id, non_null(:id)
  end

  object :constraint_mutations do
    @desc ConstraintDocs.create()
    field :create_constraint, type: :constraint_payload do
      arg(:input, :create_constraint_params)
      middleware(&preload_decision/2)
      resolve(&ConstraintResolver.create/2)
      middleware(&build_payload/2)
    end

    @desc ConstraintDocs.update()
    field :update_constraint, type: :constraint_payload do
      arg(:input, :update_constraint_params)
      middleware(&preload_decision/2)
      resolve(&ConstraintResolver.update/2)
      middleware(&build_payload/2)
    end

    @desc ConstraintDocs.delete()
    field :delete_constraint, type: :constraint_payload do
      arg(:input, :delete_option_params)
      middleware(&preload_decision/2)
      resolve(&ConstraintResolver.delete/2)
      middleware(&build_payload/2)
    end
  end
end
