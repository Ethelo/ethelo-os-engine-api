defmodule EtheloApi.Serialization.DecisionImport do

  require OK
  require Poison
  require Logger

  use OK.Pipe

  alias EtheloApi.Repo
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.OptionCategory
  alias EtheloApi.Structure.OptionDetail
  alias EtheloApi.Structure.OptionFilter
  alias EtheloApi.Structure.Option
  alias EtheloApi.Structure.OptionDetailValue
  alias EtheloApi.Structure.Criteria
  alias EtheloApi.Structure.Calculation
  alias EtheloApi.Structure.Constraint
  alias EtheloApi.Structure.Variable
  alias Engine.Scenarios.ScenarioConfig

  alias EtheloApi.Structure
  alias EtheloApi.Serialization.Import.ImportError
  alias EtheloApi.Serialization.Import.Context

  def insert_record(struct_type, attributes) do
    attributes = add_slug(attributes)
    Repo.insert! struct(struct_type, attributes)
  end

  defp add_slug(%{slug: nil, title: title} = struct) do
    Map.put(struct, :slug, UniqueSlug.string_to_slug(title))
  end
  defp add_slug(%{slug: _} = struct) do
    struct
  end
  defp add_slug(%{title: _} = struct) do
    struct |> Map.put(:slug, nil) |> add_slug()
  end
  defp add_slug(struct) when is_list(struct) do
    struct |> Enum.into(%{}) |> add_slug()
  end
  defp add_slug(struct) do
    struct
  end

  def import(export, options \\ []) do
    OK.for do
      options <- validate_options(options)
      decision_export <- decode_export(export)
      decision_import <- EtheloApi.Repo.transaction(fn ->
        OK.try do
          context <- %Context{export: decision_export, options: options}
                   |> Context.add_one(:decision, &process_decision/2)
                  ~>> Context.add_many(:criterias, &process_criteria/2)
                  ~>> Context.add_many(:option_categories, &process_option_category/2)
                  ~>> Context.add_many(:options, &process_option/2)
                  ~>> Context.add_many(:option_details, &process_option_detail/2)
                  ~>> Context.add_many(:option_detail_values, &process_option_detail_value/2)
                  ~>> Context.add_many(:option_filters, &process_option_filter/2)
                  ~>> Context.add_many(:variables, &process_variable/2)
                  ~>> Context.add_many(:calculations, &process_calculation/2)
                  ~>> Context.add_many(:constraints, &process_constraint/2)
                  ~>> Context.add_many(:scenario_configs, &process_scenario_config/2)
                  ~>> update_option_categories()

        after
          Logger.debug("import done, ensuring filters")

          EtheloApi.Structure.ensure_filters_and_vars(context.decision)
          context.decision
        rescue
          error ->
            Logger.debug("error #{error}")

            EtheloApi.Repo.rollback(error)
        end
      end, timeout: :infinity)
      decision = Structure.get_decision(decision_import.id)
    after
      decision
    end
  end

  defp decode_export(export) do
    case Poison.decode(export) do
      {:ok, %{"decision" => decision_export}} ->
        {:ok, decision_export}
      {:ok, _} ->
        {:error, %ImportError{field: :decision, reason: :not_found}}
      {:error, :invalid, position} when is_integer(position) ->
        {:error, %ImportError{reason: {:invalid_json, "invalid JSON at position #{position}"}}}
      {:error, reason} ->
        {:error, %ImportError{reason: {:invalid_json, "invalid JSON: #{inspect reason}"}}}
    end
  end

  defp validate_options(options) do
    OK.for do
      options <-
        options |> validate_options_binary
               ~>> validate_options_slug
    after
      options
    end
  end

  defp validate_options_binary(options) do
    {:ok, options |> Keyword.take([:title, :slug, :info])
                  |> Enum.filter(fn({_, value}) -> is_binary(value) end)}
  end

  defp validate_options_slug(options) do
    slug = Keyword.get(options, :slug)
    if is_binary(slug) and length(Structure.list_decisions(%{slug: slug})) > 0 do
      {:error, %ImportError{field: :decision, reason: :duplicate_slug}}
    else
      {:ok, options}
    end
  end

  defp process_decision(context, data) do
    OK.for do
      title <- Context.fetch(data, "title")

      title = Keyword.get(context.options, :title, title)
      slug = Keyword.get(context.options, :slug)
      info = Keyword.get(context.options, :info, Map.get(data, "info"))
      language = Keyword.get(context.options, :language, Map.get(data, "language"))
      max_users = Map.get(data, "max_users")
      keywords = Map.get(data, "keywords")

      attributes = [{:title, title}, {:slug, slug}, {:info, info}, {:max_users, max_users}, {:language, language}]
                |> Enum.filter(fn({_, value}) -> is_binary(value) || is_integer(value) end)
                |> Map.new
                |> Map.put(:copyable, false)
                |> Map.put(:internal, false)
    after
      %Decision{}
      |> Decision.import_changeset(attributes)
      |> Repo.insert()
    end
  end

  defp process_criteria(context, data) do
    OK.for do
      title <- Context.fetch(data, "title")
      bins <- Context.fetch(data, "bins")
      optional = Context.take(data, [:slug, :info, :weighting, :support_only, :deleted, :sort, :apply_participant_weights])
    after
      attributes =  %{decision: context.decision, title: title, bins: bins} |> Map.merge(optional)
      insert_record(Criteria, attributes)
    end
  end

  defp process_option_category(context, data) do
    OK.for do
      title <- Context.fetch(data, "title")
      weighting <- Context.fetch(data, "weighting")
      optional = Context.take(data, [
        :slug, :info, :deleted, :apply_participant_weights, :results_title, :sort,
        :xor, :triangle_base, :scoring_mode, :voting_style,
        :budget_percent, :flat_fee, :vote_on_percent, :quadratic, :keywords,
        ])
    after
      attributes = %{decision: context.decision, title: title, weighting: weighting} |> Map.merge(optional)
      insert_record(OptionCategory, attributes)
    end
  end

  defp update_option_categories(%{export: export} = context) do
    Enum.each(Map.get(export, "option_categories", []), fn(option_category_data) ->
      lookups = [
        {:options, :default_low_option_id},
        {:options, :default_high_option_id},
        {:option_details, :primary_detail_id},
      ]

      associations = Context.take_ids(context, option_category_data, lookups)
      id = Map.get(option_category_data, "id")
      option_category = Map.get(context.fields, :option_categories ) |> Map.get(id)
      EtheloApi.Structure.update_option_category(option_category, associations, false)

    end)

    {:ok, context}

  end

  defp process_option(context, data) do
    OK.for do
      title <- Context.fetch(data, "title")
      optional = Context.take(data, [:slug, :results_title, :info, :determinative, :enabled, :deleted, :sort])
      associations = Context.take_ids(context, data, [{:option_categories, :option_category_id}])
    after
      attributes =  %{decision: context.decision, title: title} |> Map.merge(optional) |> Map.merge(associations)
      insert_record(Option, attributes)
    end
  end

  defp process_option_detail(context, data) do
    OK.for do
      title <- Context.fetch(data, "title")
      format <- Context.fetch(data, "format")
      optional = Context.take(data, [:slug, :public, :sort, :display_hint, :input_hint])
    after
      attributes =  %{decision: context.decision, title: title, format: format} |> Map.merge(optional)
      insert_record(OptionDetail, attributes)
    end
  end

  defp process_option_detail_value(context, data) do
    OK.for do
      optional = Context.take(data, [:value])
      associations = Context.take_ids(context, data, [{:options, :option_id},
                                                      {:option_details, :option_detail_id}])
    after
      attributes =  %{decision: context.decision } |> Map.merge(associations) |>  Map.merge(optional)
      insert_record(OptionDetailValue, attributes)
    end
  end

  defp process_option_filter(context, data) do
    OK.for do
      title <- Context.fetch(data, "title")
      match_mode <- Context.fetch(data, "match_mode")
      optional = Context.take(data, [:slug, :match_value])
      associations = Context.take_ids(context, data, [{:option_details, :option_detail_id},
                                                      {:option_categories, :option_category_id}])
    after
      attributes = %{decision: context.decision, title: title, match_mode: match_mode}
        |> Map.merge(optional)
        |> Map.merge(associations)
      insert_record(OptionFilter, attributes)
    end
  end

  defp process_variable(context, data) do
    OK.for do
      title <- Context.fetch(data, "title")
      method <- Context.fetch(data, "method")
      optional = Context.take(data, [:slug])
      associations = Context.take_ids(context, data, [{:option_details, :option_detail_id},
                                                      {:option_filters, :option_filter_id}])
    after
      attributes = %{decision: context.decision, title: title, method: method}
                  |> Map.merge(optional)
                  |> Map.merge(associations)
      insert_record(Variable, attributes)
    end
  end

  defp process_calculation(context, data) do
    OK.for do
      title <- Context.fetch(data, "title")
      expression <- Context.fetch(data, "expression")
      optional = Context.take(data, [:slug, :display_hint, :public, :personal_results_title, :sort])
    after
      attributes = %{decision: context.decision, title: title, expression: expression} |> Map.merge(optional)
      insert_record(Calculation, attributes)
   end
  end

  defp process_constraint(context, data) do
    OK.for do
      title <- Context.fetch(data, "title")
      operator <- Context.fetch(data, "operator")
      rhs <- Context.fetch(data, "rhs")
      optional = Context.take(data, [:slug, :lhs, :rhs, :enabled, :relaxable])
      associations = Context.take_ids(context, data, [{:option_filters, :option_filter_id},
                                                      {:variables, :variable_id},
                                                      {:calculations, :calculation_id}])
    after
      attributes = %{decision: context.decision, title: title, operator: operator, rhs: rhs}
          |> Map.merge(optional)
          |> Map.merge(associations)

      insert_record(Constraint, attributes)
    end
  end

  defp process_scenario_config(context, data) do
    OK.for do
      title <- Context.fetch(data, "title")
      bins <- Context.fetch(data, "bins")
      support_only <- Context.fetch(data, "support_only")
      per_option_satisfaction <- Context.fetch(data, "per_option_satisfaction")
      normalize_satisfaction = Context.get(data, "normalize_satisfaction", true)
      normalize_influents <- Context.fetch(data, "normalize_influents")
      ttl <- Context.fetch(data, "ttl")
      solve_interval <- Context.fetch(data, "solve_interval")
      engine_timeout <- Context.fetch(data, "engine_timeout")
      max_scenarios <- Context.fetch(data, "max_scenarios")
      ci <- Context.fetch(data, "ci")
      tipping_point <- Context.fetch(data, "tipping_point")
      enabled <- Context.fetch(data, "enabled")
      skip_solver <- Context.fetch(data, "skip_solver")

      quadratic <- Context.fetch(data, "quadratic")
      optional = Context.take(data, [:slug, :quad_user_seeds, :quad_total_available, :quad_cutoff, :quad_max_allocation, :quad_round_to, :quad_seed_percent, :quad_vote_percent])

    after
      attributes = %{
          decision: context.decision,
          title: title,
          bins: bins,
          support_only: support_only,
          quadratic: quadratic,
          per_option_satisfaction: per_option_satisfaction,
          normalize_satisfaction: normalize_satisfaction,
          normalize_influents: normalize_influents,
          ttl: ttl,
          solve_interval: solve_interval,
          engine_timeout: engine_timeout,
          max_scenarios: max_scenarios,
          ci: ci |> Decimal.from_float(),
          tipping_point: tipping_point |> Decimal.from_float(),
          enabled: enabled,
          skip_solver: skip_solver,
          }
         |> Map.merge(optional)
      insert_record(ScenarioConfig, attributes)
    end
  end
end
