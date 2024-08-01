defmodule GraphQL.EtheloApi.AdminSchema.Constraint do
  @moduledoc """
  Base access to Constraints
  """
  use DocsComposer, module: EtheloApi.Structure.Docs.Constraint
  alias GraphQL.EtheloApi.Docs.Constraint, as: ConstraintDocs

  use Absinthe.Schema.Notation
  import GraphQL.EtheloApi.ResolveHelper
  import Kronky.Payload, only: [payload_object: 2, build_payload: 2]
  alias GraphQL.EtheloApi.Resolvers.Constraint, as: ConstraintResolver
  alias GraphQL.EtheloApi.Resolvers.Variable, as: VariableResolver
  alias GraphQL.EtheloApi.Resolvers.Calculation, as: CalculationResolver
  alias GraphQL.EtheloApi.Resolvers.OptionFilter, as: OptionFilterResolver

  enum :constraint_operators, description: @doc_map.strings.operator do
    value :equal_to, description: @doc_map.strings.operator_equal_to
    value :less_than_or_equal_to, description: @doc_map.strings.operator_less_than_or_equal_to
    value :greater_than_or_equal_to, description: @doc_map.strings.operator_greater_than_or_equal_to
    value :between, description: @doc_map.strings.operator_between
  end

  enum :single_boundary_constraint_operators, description: @doc_map.strings.operator do
    value :equal_to, description: @doc_map.strings.operator_equal_to
    value :less_than_or_equal_to, description: @doc_map.strings.operator_less_than_or_equal_to
    value :greater_than_or_equal_to, description: @doc_map.strings.operator_greater_than_or_equal_to
  end

  object :constraint do
    field :id, non_null(:id), description: @doc_map.strings.id
    field :title, non_null(:string), description: @doc_map.strings.title
    field :slug, non_null(:string), description: @doc_map.strings.slug
    field :operator, non_null(:constraint_operators), description: @doc_map.strings.operator
    field :enabled, :boolean, description: @doc_map.strings.enabled
    field :relaxable, :boolean, description: @doc_map.strings.relaxable
    field :value, :float, description: @doc_map.strings.value, resolve: &ConstraintResolver.value/3
    field :between_high, :float, description: @doc_map.strings.between_high, resolve: &ConstraintResolver.between_high/3
    field :between_low, :float, description: @doc_map.strings.between_low, resolve: &ConstraintResolver.between_low/3
    field :variable, :variable,
      description: @doc_map.strings.variable,
      resolve: &VariableResolver.batch_load_belongs_to/3
    field :calculation, :calculation,
      description: @doc_map.strings.calculation,
      resolve: &CalculationResolver.batch_load_belongs_to/3
    field :option_filter, non_null(:option_filter),
      description: @doc_map.strings.option_filter,
      resolve: &OptionFilterResolver.batch_load_belongs_to/3
    field :inserted_at, non_null(:datetime), description: @doc_map.strings.inserted_at
    field :updated_at, non_null(:datetime), description: @doc_map.strings.updated_at
  end

  object :constraint_list do
    field :constraints, list_of(:constraint) do
      arg :id, :id, description: "Filter by Constraint id"
      arg :slug, :string, description: "Filter by Constraint slug"
      arg :enabled, :boolean, description: @doc_map.strings.enabled
      arg :calculation_id, :id, description: @doc_map.strings.calculation_id
      arg :variable_id, :id, description: @doc_map.strings.variable_id
      arg :option_filter_id, :id, description: @doc_map.strings.option_filter_id
      resolve &ConstraintResolver.list/3
    end
  end

  input_object :base_constraint_params do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :calculation_id, :id, description: @doc_map.strings.calculation_id
    field :variable_id, :id, description: @doc_map.strings.calculation_id
    field :option_filter_id, :id, description: @doc_map.strings.calculation_id
    field :enabled, :boolean, description: @doc_map.strings.enabled
    field :relaxable, :boolean, description: @doc_map.strings.relaxable
    field :slug, :string, description: @doc_map.strings.slug
  end

  # mutations
  input_object :create_single_boundary_constraint_params, description: ConstraintDocs.create_single_boundary_constraint() do
    import_fields :base_constraint_params
    field :title, non_null(:string), description: @doc_map.strings.title
    field :operator, non_null(:single_boundary_constraint_operators), description: @doc_map.strings.operator
    field :value, non_null(:float), description: @doc_map.strings.value
  end

  input_object :update_single_boundary_constraint_params, description: ConstraintDocs.update_single_boundary_constraint() do
    import_fields :base_constraint_params
    field :id, non_null(:id), description: @doc_map.strings.id
    field :title, :string, description: @doc_map.strings.title
    field :operator, :single_boundary_constraint_operators, description: @doc_map.strings.operator
    field :value, :float, description: @doc_map.strings.value
  end

  payload_object(:single_boundary_constraint_payload, :constraint)

  input_object :create_between_constraint_params, description: ConstraintDocs.create_between_constraint() do
    import_fields :base_constraint_params
    field :title, non_null(:string), description: @doc_map.strings.title
    field :between_high, non_null(:float), description: @doc_map.strings.between_high
    field :between_low, non_null(:float), description: @doc_map.strings.between_low
  end

  input_object :update_between_constraint_params, description: ConstraintDocs.update_between_constraint() do
    import_fields :base_constraint_params
    field :id, non_null(:id), description: @doc_map.strings.id
    field :title, :string, description: @doc_map.strings.title
    field :between_high, non_null(:float), description: @doc_map.strings.between_high
    field :between_low, non_null(:float), description: @doc_map.strings.between_low
  end

  payload_object(:between_constraint_payload, :constraint)

  input_object :delete_constraint_params, description: ConstraintDocs.delete() do
    field :decision_id, non_null(:id), description: @doc_map.strings.decision_id
    field :id, non_null(:id), description: @doc_map.strings.id
  end

  # provide an object that can be imported into the base mutations query.
  object :constraint_mutations do

    field :create_single_boundary_constraint, type: :single_boundary_constraint_payload, description: ConstraintDocs.create_single_boundary_constraint() do
      arg :input, :create_single_boundary_constraint_params
      resolve mutation_resolver(&ConstraintResolver.create/2)
      middleware &build_payload/2
    end

    field :update_single_boundary_constraint, type: :single_boundary_constraint_payload, description: ConstraintDocs.update_single_boundary_constraint() do
      arg :input, :update_single_boundary_constraint_params
      resolve mutation_resolver(&ConstraintResolver.update/2)
      middleware &build_payload/2
    end

   field :create_between_constraint, type: :between_constraint_payload, description: ConstraintDocs.create_between_constraint() do
      arg :input, :create_between_constraint_params
      resolve mutation_resolver(&ConstraintResolver.create/2)
      middleware &build_payload/2
    end

    field :update_between_constraint, type: :between_constraint_payload, description: ConstraintDocs.update_between_constraint() do
      arg :input, :update_between_constraint_params
      resolve mutation_resolver(&ConstraintResolver.update/2)
      middleware &build_payload/2
    end

    field :delete_constraint, type: :single_boundary_constraint_payload, description: ConstraintDocs.delete() do
      arg :input, :delete_option_params
      resolve mutation_resolver(&ConstraintResolver.delete/2)
      middleware &build_payload/2
    end
  end
end
