defmodule EtheloApi.Graphql.Schema do
  @moduledoc """
  Base Schema for all graphql.
  """

  use Absinthe.Schema
  alias EtheloApi.Graphql.Resolvers.Decision, as: DecisionResolver
  import EtheloApi.Graphql.Middleware

  import_types(Absinthe.Type.Custom)
  import_types(AbsintheErrorPayload.ValidationMessageTypes)
  import_types(EtheloApi.Graphql.Schemas.Decision)

  object :date_count do
    field :datetime, non_null(:datetime)
    field :count, non_null(:integer)
  end

  import_types(EtheloApi.Graphql.Schemas.Criteria)
  import_types(EtheloApi.Graphql.Schemas.Calculation)
  import_types(EtheloApi.Graphql.Schemas.Constraint)
  import_types(EtheloApi.Graphql.Schemas.Option)
  import_types(EtheloApi.Graphql.Schemas.OptionCategory)
  import_types(EtheloApi.Graphql.Schemas.OptionDetail)
  import_types(EtheloApi.Graphql.Schemas.OptionDetailValue)
  import_types(EtheloApi.Graphql.Schemas.OptionFilter)
  import_types(EtheloApi.Graphql.Schemas.Variable)
  import_types(EtheloApi.Graphql.Schemas.ScenarioConfig)
  import_types(EtheloApi.Graphql.Schemas.Participant)
  import_types(EtheloApi.Graphql.Schemas.BinVote)
  import_types(EtheloApi.Graphql.Schemas.OptionCategoryBinVote)
  import_types(EtheloApi.Graphql.Schemas.OptionCategoryRangeVote)
  import_types(EtheloApi.Graphql.Schemas.CriteriaWeight)
  import_types(EtheloApi.Graphql.Schemas.OptionCategoryWeight)

  import_types(EtheloApi.Graphql.Schemas.ScenarioSet)
  import_types(EtheloApi.Graphql.Schemas.SolveDump)
  import_types(EtheloApi.Graphql.Schemas.Scenario)
  import_types(EtheloApi.Graphql.Schemas.ScenarioDisplay)
  import_types(EtheloApi.Graphql.Schemas.ScenarioStats)

  object :decision_query_payload do
    # @desc  "meta information about query"
    field :meta, non_null(:meta)

    field :summary, :decision_summary,
      resolve: fn parent, _, _ -> {:ok, Map.get(parent, :decision)} end

    import_fields(:bin_vote_list)
    import_fields(:bin_vote_activity)
    import_fields(:calculation_list)
    import_fields(:constraint_list)
    import_fields(:criteria_list)
    import_fields(:criteria_weight_list)
    import_fields(:option_category_bin_vote_list)
    import_fields(:option_category_bin_vote_activity)
    import_fields(:option_category_list)
    import_fields(:option_category_range_vote_list)
    import_fields(:option_category_range_vote_activity)
    import_fields(:option_category_weight_list)
    import_fields(:option_detail_list)
    import_fields(:option_filter_list)
    import_fields(:option_list)
    import_fields(:participant_list)
    import_fields(:scenario_config_list)
    import_fields(:scenario_set_list)
    import_fields(:variable_list)
  end

  object :meta do
    @desc "Indicates if the query completed successfully or not. "
    field :successful, non_null(:boolean)

    @desc "A list of error messages. Only Present if query was not successful"
    field :messages, list_of(:validation_message)

    @desc "UTC Date & Time query was complete"
    field :completed_at, non_null(:datetime)
  end

  query do
    import_fields(:decision_list)

    @desc "returns the Decision matching the modifiers, or the last updated Decision"
    field :decision, :decision_query_payload do
      @desc "Filter by Decision id"
      arg(:decision_id, :id)
      @desc "Filter by Decision slug"
      arg(:decision_slug, :string)
      resolve(&DecisionResolver.match_decision/2)
      middleware(&add_payload_meta/2)
    end
  end

  mutation do
    import_fields(:bin_vote_mutations)
    import_fields(:calculation_mutations)
    import_fields(:constraint_mutations)
    import_fields(:criteria_mutations)
    import_fields(:criteria_weight_mutations)
    import_fields(:decision_mutations)
    import_fields(:option_category_bin_vote_mutations)
    import_fields(:option_category_mutations)
    import_fields(:option_category_range_vote_mutations)
    import_fields(:option_category_weight_mutations)
    import_fields(:option_detail_mutations)
    import_fields(:option_detail_value_mutations)
    import_fields(:option_filter_mutations)
    import_fields(:option_mutations)
    import_fields(:participant_mutations)
    import_fields(:scenario_config_mutations)
    import_fields(:variable_mutations)
  end

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(:repo, EtheloApi.Graphql.DataSource.repo_datasource())
      |> Dataloader.add_source(
        :option_filters,
        EtheloApi.Graphql.Resolvers.OptionFilter.datasource()
      )
      |> Dataloader.add_source(:variables, EtheloApi.Graphql.Resolvers.Variable.datasource())

    Map.put(ctx, :loader, loader)
  end

  def plugins, do: [Absinthe.Middleware.Dataloader | Absinthe.Plugin.defaults()]
end
