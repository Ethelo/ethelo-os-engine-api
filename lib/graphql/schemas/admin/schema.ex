defmodule EtheloApi.GraphQL.AdminSchema do
  @moduledoc """
  GraphQL Endpoint configuration. Please import all types, queries and mutations.
  """
  use Absinthe.Schema
  import GraphQL.EtheloApi.Middleware
  import_types Absinthe.Type.Custom

  #alias GraphQL.EtheloApi.Docs.Decision, as: DecisionDocs
  alias GraphQL.EtheloApi.Resolvers.Decision, as: DecisionResolver

  def evaluate_graphql(query, options \\ []) do
    Absinthe.run(query, EtheloApi.GraphQL.AdminSchema, options)
  end

  import_types GraphQL.EtheloApi.AdminSchema.Decision
  import_types GraphQL.EtheloApi.AdminSchema.Criteria
  import_types GraphQL.EtheloApi.AdminSchema.Calculation
  import_types GraphQL.EtheloApi.AdminSchema.Constraint
  import_types GraphQL.EtheloApi.AdminSchema.Option
  import_types GraphQL.EtheloApi.AdminSchema.OptionCategory
  import_types GraphQL.EtheloApi.AdminSchema.OptionDetail
  import_types GraphQL.EtheloApi.AdminSchema.OptionDetailValue
  import_types GraphQL.EtheloApi.AdminSchema.OptionFilter
  import_types GraphQL.EtheloApi.AdminSchema.Variable
  import_types GraphQL.EtheloApi.AdminSchema.ScenarioConfig
  import_types GraphQL.EtheloApi.AdminSchema.ScenarioDisplay
  import_types GraphQL.EtheloApi.AdminSchema.ScenarioSet
  import_types GraphQL.EtheloApi.AdminSchema.SolveDump
  import_types GraphQL.EtheloApi.AdminSchema.BinVote
  import_types GraphQL.EtheloApi.AdminSchema.OptionCategoryBinVote
  import_types GraphQL.EtheloApi.AdminSchema.OptionCategoryRangeVote
  import_types GraphQL.EtheloApi.AdminSchema.CriteriaWeight
  import_types GraphQL.EtheloApi.AdminSchema.OptionCategoryWeight
  import_types GraphQL.EtheloApi.AdminSchema.Participant
  import_types Kronky.ValidationMessageTypes

  object :meta do
    field :successful, non_null(:boolean), description: "Indicates if the query completed successfully or not. "
    field :messages, list_of(:validation_message), description: "A list of error messages. Only Present if query was not successful"
    field :completed_at, non_null(:datetime), description: "Date & Time query was complete"
  end

  object :decision_query_payload do
    field :meta, non_null(:meta), description: "meta information about query"
    field :summary, :decision_summary, resolve: fn(parent, _, _) -> {:ok, Map.get(parent, :decision)} end
    import_fields :criteria_list
    import_fields :option_category_list
    import_fields :option_detail_list
    import_fields :option_filter_list
    import_fields :option_list
    import_fields :scenario_config_list
    import_fields :variable_list
    import_fields :variable_suggestion_list
    import_fields :calculation_list
    import_fields :constraint_list
    import_fields :scenario_set_list
    import_fields :solve_dump_list
    import_fields :participant_list
    import_fields :option_category_weight_list
    import_fields :criteria_weight_list
    import_fields :bin_vote_list
    import_fields :option_category_bin_vote_list
    import_fields :option_category_range_vote_list
  end

  query do
    import_fields :decision_list

    field :decision, :decision_query_payload, description: "returns the Decision matching the filters, or the last updated decision" do
      arg :decision_id, :id, description: "Filter by decision id"
      arg :decision_slug, :string, description: "Filter by decision slug"
      resolve &DecisionResolver.match_decision/2
      middleware &post_resolve_payload/2
    end
  end

  mutation do
    import_fields :decision_mutations
    import_fields :criteria_mutations
    import_fields :option_category_mutations
    import_fields :option_detail_mutations
    import_fields :option_detail_value_mutations
    import_fields :option_filter_mutations
    import_fields :option_mutations
    import_fields :scenario_config_mutations
    import_fields :variable_mutations
    import_fields :calculation_mutations
    import_fields :constraint_mutations
    import_fields :bin_vote_mutations
    import_fields :option_category_bin_vote_mutations
    import_fields :option_category_range_vote_mutations
    import_fields :criteria_weight_mutations
    import_fields :option_category_weight_mutations
    import_fields :participant_mutations
    import_fields :scenario_set_mutations
  end

end
