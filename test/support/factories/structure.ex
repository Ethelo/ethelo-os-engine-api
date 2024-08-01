defmodule EtheloApi.Structure.Factory do
  @moduledoc """
  Factories to use when testing Ethelo Decisions
  """
  use EtheloApi.BaseFactory, module: __MODULE__
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

  def load_file(filename) do
    File.read!(Path.join("#{:code.priv_dir(:ethelo)}", filename))
  end

  ## Calculation ##

  def calculation_defaults() do
    %Calculation{
      title: "Calculation#{unique_int()}",
      personal_results_title: "CalculationPR#{unique_int()}",
      slug: "calculation-#{unique_int()}",
      display_hint: short_sentence(),
      expression: "#{Enum.random(1..100)}",
      public: random_bool(),
    }
  end

  def calculation_deps() do
    decision = create_decision()
    calculation_deps(decision)
  end

  def calculation_deps(%Decision{} = decision) do
    %{decision: decision}
  end

  def calculation_with_variables_deps() do
    decision = create_decision()
    calculation_with_variables_deps(decision)
  end

  def calculation_with_variables_deps(%Decision{} = decision) do
    ofv_deps = create_filter_variable(decision)
    ofv_deps = ofv_deps |> Map.put(:filter_variable, ofv_deps.variable) |> Map.drop([:variable])

    odv_deps = create_detail_variable(decision)
    odv_deps = odv_deps |> Map.put(:detail_variable, odv_deps.variable) |> Map.drop([:variable])
    Map.merge(ofv_deps, odv_deps)
  end

  def create_calculation() do
    decision = create_decision()
    create_calculation(decision)
  end

  def create_calculation(%Decision{} = decision, overrides \\ %{}) do
    deps = calculation_deps(decision)
    values = Map.merge(deps, overrides)
    calculation = insert(calculation_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:calculation, calculation)
  end

  def create_calculation_without_deps(%Decision{} = decision, values \\ %{}) do
    values = Map.put(values, :decision, decision)
    insert(calculation_defaults(), values)
  end

  def create_calculation_with_variables() do
    decision = create_decision()
    create_calculation_with_variables(decision)
  end

  def create_calculation_with_variables(%Decision{} = decision, overrides \\ %{}) do
    deps = calculation_with_variables_deps(decision)
    values = Map.merge(deps, overrides)
    values = Map.get(values, :expression) || Map.put(values, :expression, "#{values.filter_variable.slug} + #{values.detail_variable.slug}")
    values = Map.get(values, :variables) || Map.put(values, :variables, [values.filter_variable, values.detail_variable])
    calculation = insert(calculation_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:calculation, calculation)
  end

  def delete_calculation(id) do
    Calculation |> do_delete_all(id)
  end

  ## Constraint ##

  def constraint_single_defaults() do
    %Constraint{
      title: "Constraint#{unique_int()}",
      slug: "constraint-#{unique_int()}",
      operator: :less_than_or_equal_to,
      rhs: Enum.random(100..1000) / 10,
      lhs: nil,
      relaxable: false,
    }
  end

  def constraint_between_defaults() do
    %Constraint{
      title: "Constraint#{unique_int()}",
      slug: "constraint-#{unique_int()}",
      operator: :between,
      relaxable: false,
      rhs: Enum.random(501..1000) / 10,
      lhs: Enum.random(100..500) / 10,
    }
  end

  def calculation_constraint_deps() do
    decision = create_decision()
    calculation_constraint_deps(decision)
  end

  def calculation_constraint_deps(%Decision{} = decision)  do
    Map.merge(
      create_calculation(decision),
      create_option_category_filter(decision)
    )
  end

  def create_calculation_constraint() do
    decision = create_decision()
    create_calculation_constraint(decision)
  end

  def create_calculation_constraint(%Decision{} = decision) do
    create_calculation_constraint(decision, %{})
  end

  def create_calculation_constraint(%Decision{} = decision, %Calculation{} = calculation) do
    create_calculation_constraint(decision, %{calculation: calculation})
  end

  def create_calculation_constraint(%Decision{} = decision, %{} = overrides) do
    deps = decision |> calculation_constraint_deps()
    values = deps |> Map.put(:method, :sum_selected) |> Map.merge(overrides)
    constraint = if Map.get(values, :operator) == :between do
      insert(constraint_between_defaults(), values)
    else
      insert(constraint_single_defaults(), values)
    end
    values |> Map.take(Map.keys(deps)) |> Map.put(:constraint, constraint)
  end

  def variable_constraint_deps() do
    decision = create_decision()
    variable_constraint_deps(decision)
  end

  def variable_constraint_deps(%Decision{} = decision) do
    Map.merge(
      create_detail_variable(decision),
      create_option_category_filter(decision)
    )
  end

  def create_variable_constraint() do
    decision = create_decision()
    create_variable_constraint(decision)
  end

  def create_variable_constraint(%Decision{} = decision, overrides \\ %{}) do
    deps = decision |> variable_constraint_deps()
    values = deps |> Map.put(:method, :count_selected) |> Map.merge(overrides)
    constraint = if Map.get(values, :operator) == :between do
      insert(constraint_between_defaults(), values)
    else
      insert(constraint_single_defaults(), values)
    end
    values |> Map.take(Map.keys(deps)) |> Map.put(:constraint, constraint)
  end

  def create_constraint_without_deps(%Decision{} = decision, %{} = values) do
    values = Map.put(values, :decision, decision)
    constraint = if Map.get(values, :operator) == :between do
      insert(constraint_between_defaults(), values)
    else
      insert(constraint_single_defaults(), values)
    end
    constraint
  end

  def delete_constraint(id) do
    Constraint |> do_delete_all(id)
  end

  ## Criteria ##

  def criteria_defaults() do
    %Criteria{
      title: "Criteria#{unique_int()}",
      slug: "criteria#{unique_int()}",
      info: short_sentence(),
      bins: Enum.random(1..9),
      support_only: random_bool(),
      apply_participant_weights: random_bool(),
      weighting: Enum.random(1..99),
    }
  end

  def criteria_deps() do
    decision = create_decision()
    criteria_deps(decision)
  end

  def criteria_deps(%Decision{} = decision) do
    %{decision: decision}
  end

  def create_criteria() do
    decision = create_decision()
    create_criteria(decision)
  end

  def create_criteria(%Decision{} = decision, overrides \\ %{}) do
    deps = criteria_deps(decision)
    values = Map.merge(deps, overrides)
    criteria = insert(criteria_defaults(), values)
    Map.put(deps, :criteria, criteria)
  end

  def create_criteria_without_deps(%Decision{} = decision, %{} = values) do
    values = Map.put(values, :decision, decision)
    insert(criteria_defaults(), values)
  end

  def delete_criteria(id) do
    Criteria |> do_delete_all(id)
  end

  ## Decision ##

  def decision_defaults() do
    %Decision{
      title: "Decision#{unique_int()}",
      slug: "decision#{unique_int()}",
      info: short_sentence(),
      copyable: false,
      internal: false,
      language: "en",
      keywords: [short_sentence(), short_sentence()],
      max_users: 25,
      published_decision_hash: "#{unique_int()}",
      preview_decision_hash: "#{unique_int()}",
      influent_hash: "#{unique_int()}",
      weighting_hash: "#{unique_int()}",
    }
  end

  def create_decision(values \\ %{}) do
    insert(decision_defaults(), values)
  end

  def delete_decision(id) do
    Decision |> do_delete_all(id)
  end

  ## Option ##

  def option_defaults() do
    %Option{
      title: "Option#{unique_int()}",
      slug: "option#{unique_int()}",
      info: short_sentence(),
      enabled: true,
      determinative: false,
      }
  end

  def option_deps() do
    decision = create_decision()
    option_deps(decision)
  end

  def option_deps(%Decision{} = decision) do
    create_option_category(decision)
  end

  def create_option() do
    decision = create_decision()
    create_option(decision)
  end

  def create_option(%Decision{} = decision, overrides \\ %{}) do
    deps = option_deps(decision)
    values = Map.merge(deps, overrides)
    option = insert(option_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:option, option)
  end

  def create_option_without_deps(%Decision{} = decision, %{} = values) do
    values = Map.put(values, :decision, decision)
    insert(option_defaults(), values)
  end

  def delete_option(id) do
    Option |> do_delete_all(id)
  end

  ## Option Category ##

  def option_category_defaults() do

    %OptionCategory{
      title: "OptionCategory#{unique_int()}",
      slug: "option-category#{unique_int()}",
      info: short_sentence(),
      keywords: short_sentence(),
      weighting: Enum.random(1..99),
      xor: random_bool(),
      apply_participant_weights: random_bool(),
      scoring_mode: :none,
      budget_percent: Enum.random(5..50) / 100.0,
      flat_fee: Enum.random(100..500) / 100.0,
      results_title: "ocrt#{unique_int()}",
      vote_on_percent: random_bool(),
      quadratic: false, # set this specifically as it has side effects
      triangle_base: Enum.random(1..3),
      voting_style: :one,
    }
  end

  def option_category_deps() do
    decision = create_decision()
    option_category_deps(decision)
  end

  def option_category_deps(%Decision{} = decision) do
    %{decision: decision}
  end

  def option_category_with_detail_deps() do
    decision = create_decision()
    option_category_with_detail_deps(decision)
  end

  def option_category_with_detail_deps(%Decision{} = decision) do
    %{option_detail: option_detail} = create_option_detail(decision, :float)
    option_category_with_detail_deps(decision, option_detail)
  end

  def option_category_with_detail_deps(%Decision{} = decision, %OptionDetail{} = primary_detail) do
    %{decision: decision, primary_detail: primary_detail}
  end

  def create_option_category() do
    decision = create_decision()
    create_option_category(decision)
  end

  def create_option_category(%Decision{} = decision, overrides \\ %{}) do
    deps = option_category_deps(decision)
    values = Map.merge(deps, overrides)
    option_category = insert(option_category_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:option_category, option_category)
  end

  def create_option_category_with_detail() do
    decision = create_decision()
    create_option_category_with_detail(decision)
  end

  def create_option_category_with_detail(record, overrides \\ %{})

  def create_option_category_with_detail(%Decision{} = decision, overrides) do
    %{primary_detail: primary_detail} = option_category_with_detail_deps(decision)
    create_option_category_with_detail(primary_detail, overrides)
  end

  def create_option_category_with_detail(%OptionDetail{} = primary_detail, overrides) do
    deps = option_category_with_detail_deps(primary_detail.decision, primary_detail)
    values = Map.merge(deps, overrides)
    option_category = insert(option_category_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:option_category, option_category)
  end

  def create_option_category_without_deps(%Decision{} = decision, %{} = values) do
    values = Map.put(values, :decision, decision)
    insert(option_category_defaults(), values)
  end

  def delete_option_category(id) do
    OptionCategory |> do_delete_all(id)
  end

  ## OptionDetail ##

  def option_detail_defaults() do
    %OptionDetail{
      title: "OptionDetail#{unique_int()}",
      slug: "option-detail#{unique_int()}",
      display_hint: short_sentence(),
      input_hint: short_sentence(),
      public: random_bool()
    }
  end

  def option_detail_deps() do
    decision = create_decision()
    option_detail_deps(decision)
  end

  def option_detail_deps(%Decision{} = decision) do
    %{decision: decision}
  end

  def create_option_detail() do
    decision = create_decision()
    create_option_detail(decision, %{format: :string})
  end

  def create_option_detail(format) when is_atom(format) do
    decision = create_decision()
    create_option_detail(decision, %{format: format})
  end

  def create_option_detail(%Decision{} = decision) do
    create_option_detail(decision, %{format: :string})
  end

  def create_option_detail(decision, overrides \\ %{})

  def create_option_detail(%Decision{} = decision, format) when is_atom(format) do
    create_option_detail(decision, %{format: format})
  end

  def create_option_detail(%Decision{} = decision, %{} = overrides) do
    deps = option_detail_deps(decision)
    values = Map.merge(deps, overrides)
    option_detail = insert(option_detail_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:option_detail, option_detail)
  end

  def create_option_detail_without_deps(%Decision{} = decision, %{} = values) do
    values = Map.put(values, :decision, decision)
    insert(option_detail_defaults(), values)
  end

  def delete_option_detail(id) do
    OptionDetail |> do_delete_all(id)
  end

  ## OptionDetailValue ##

  def option_detail_value_defaults() do
    %OptionDetailValue{
      value: to_string(Enum.random(1..9339))
    }
  end

  def option_detail_value_deps() do
    decision = create_decision()
    option_detail_value_deps(decision)
  end

  def option_detail_value_deps(format) when is_atom(format) do
    decision = create_decision()
    option_detail_value_deps(decision, format)
  end

  def option_detail_value_deps(%Decision{} = decision) do
    option_detail_value_deps(decision, :string)
  end

  def option_detail_value_deps(%Decision{} = decision, format) when is_atom(format) do
    %{option_detail: option_detail} = create_option_detail(decision, format)
    %{option: option} = create_option(decision)
    %{option_detail: option_detail, option: option, decision: decision}
  end

  def create_option_detail_value() do
    decision = create_decision()
    create_option_detail_value(decision)
  end

  def create_option_detail_value(format) when is_atom(format) do
    decision = create_decision()
    create_option_detail_value(decision, format)
  end

  def create_option_detail_value(%Decision{} = decision) do
    create_option_detail_value(decision, :string)
  end

  def create_option_detail_value(format, value) when is_atom(format) do
    decision = create_decision()
    create_option_detail_value(decision, format, value)
  end

  def create_option_detail_value(%Decision{} = decision, format) when is_atom(format) do
    create_option_detail_value(decision, format, random_value_for_format(format))
  end

  def create_option_detail_value(%Decision{} = decision, %OptionDetail{} = option_detail) do
    create_option_detail_value(decision, option_detail, random_value_for_format(option_detail.format))
  end

  def create_option_detail_value(%Decision{} = decision, format, value) when is_atom(format) do
    deps = option_detail_value_deps(decision, format)
    values = Map.put(deps, :value, to_string(value))
    option_detail_value = insert(option_detail_value_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:option_detail_value, option_detail_value)
  end

  def create_option_detail_value(%Decision{} = decision, %OptionDetail{} = option_detail, value) do
    deps = decision |> option_detail_value_deps() |> Map.put(:option_detail, option_detail)
    values = Map.put(deps, :value, to_string(value))
    option_detail_value = insert(option_detail_value_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:option_detail_value, option_detail_value)
  end

  def create_option_detail_value(%Decision{} = decision, %Option{} = option, value) do
    deps = decision |> option_detail_value_deps() |> Map.put(:option, option)
    values = Map.put(deps, :value, to_string(value))
    option_detail_value = insert(option_detail_value_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:option_detail_value, option_detail_value)
  end

  def create_option_detail_value(%Option{} = option, %OptionDetail{} = option_detail, value) do
    deps = %{option: option, option_detail: option_detail, decision: option.decision}
    values = Map.put(deps, :value, to_string(value))
    option_detail_value = insert(option_detail_value_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:option_detail_value, option_detail_value)
  end

  def create_option_detail_value_without_deps(%Decision{} = decision, %{} = values) do
    values = Map.put(values, :decision, decision)
    insert(option_detail_value_defaults(), values)
  end

  def random_value_for_format(format) do
    case format do
      :boolean -> random_bool()
      :integer -> Enum.random(1..100)
      :float -> Enum.random(1..1000) / 100
      :string -> System.unique_integer() |> to_string() |> Base.encode64(padding: false)
    end
  end

  def delete_option_detail_value(id) do
    OptionDetailValue |> do_delete_all(id)
  end

  ## Option Filter ##

  def option_filter_defaults() do
    %OptionFilter{
      title: "OptionFilter#{unique_int()}",
      slug: "option-filter#{unique_int()}",
      match_mode: "equals",
      match_value: Faker.Commerce.color,
    }
  end

  def option_detail_filter_deps() do
    decision = create_decision()
    option_detail_filter_deps(decision, :string)
  end

  def option_detail_filter_deps(format) when is_atom(format) do
    decision = create_decision()
    option_detail_filter_deps(decision, format)
  end

  def option_detail_filter_deps(%Decision{} = decision)  do
    option_detail_filter_deps(decision, :string)
  end

  def option_detail_filter_deps(%Decision{} = decision, format) when is_atom(format) do
    create_option_detail(decision, %{format: format})
  end

  def create_option_detail_filter() do
    decision = create_decision()
    create_option_detail_filter(decision)
  end

  def create_option_detail_filter(format) when is_atom(format) do
    decision = create_decision()
    create_option_detail_filter(decision, format, random_value_for_format(format))
  end

  def create_option_detail_filter(%Decision{} = decision) do
    create_option_detail_filter(decision, %{})
  end

  def create_option_detail_filter(format, value) when is_atom(format) do
    decision = create_decision()
    create_option_detail_filter(decision, format, value)
  end

  def create_option_detail_filter(%Decision{} = decision, format) when is_atom(format) do
    create_option_detail_filter(decision, format, %{})
  end

  def create_option_detail_filter(%Decision{} = decision, %OptionDetail{} = option_detail) do
    create_option_detail_filter(decision, option_detail, random_value_for_format(option_detail.format))
  end

  def create_option_detail_filter(%Decision{} = decision, %{} = overrides) do
    create_option_detail_filter(decision, :string, overrides)
  end

  def create_option_detail_filter(%Decision{} = decision, format, value) when is_atom(format) and is_binary(value) do
    create_option_detail_filter(decision, format, %{match_value: value})
  end

  def create_option_detail_filter(%Decision{} = decision, %OptionDetail{} = option_detail, value) do
    create_option_detail_filter(decision, :string, %{match_value: value, option_detail: option_detail})
  end

  def create_option_detail_filter(%Decision{} = decision, format, overrides) do
    deps = decision |> option_detail_filter_deps(format)
    values = Map.merge(deps, overrides)
    option_filter = insert(option_filter_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:option_filter, option_filter)
  end

  def create_option_detail_filter_matching(%Decision{} = decision, %OptionDetail{} = option_detail, match_value, match_mode) do
    values = %{
      decision: decision, option_detail: option_detail, match_value: match_value, match_mode: match_mode
    }
    option_filter = insert(option_filter_defaults(), values)
    %{option_detail: option_detail, option_filter: option_filter}
  end

  def option_category_filter_deps() do
    decision = create_decision()
    option_category_filter_deps(decision)
  end

  def option_category_filter_deps(%Decision{} = decision) do
    create_option_category(decision)
  end

  def create_option_category_filter() do
    decision = create_decision()
    create_option_category_filter(decision)
  end

  def create_option_category_filter(%Decision{} = decision, overrides \\ %{}) do
    deps = decision |> option_category_filter_deps()
    values = deps |> Map.put(:match_value, "") |> Map.put(:match_mode, "in_category") |> Map.merge(overrides)
    option_filter = insert(option_filter_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:option_filter, option_filter)
  end

  def create_option_category_filter_matching(%Decision{} = decision, %OptionCategory{} = option_category, match_mode) do
    deps = decision |> option_category_filter_deps() |> Map.put(:option_category, option_category)
    values = Map.put(deps, :match_mode, match_mode)
    option_filter = insert(option_filter_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:option_filter, option_filter)
  end

  def create_all_options_filter() do
    decision = create_decision()
    create_all_options_filter(decision)
  end

  def create_option_filter_without_deps(%Decision{} = decision, %{} = values) do
    values = Map.put(values, :decision, decision)
    insert(option_filter_defaults(), values)
  end

  def create_all_options_filter(%Decision{} = decision) do
    deps = %{decision: decision}
    values = Map.merge(deps, OptionFilter.all_options_values())
    option_filter = insert(option_filter_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:option_filter, option_filter)
  end

  def delete_option_filter(id) do
    OptionFilter |> do_delete_all(id)
  end

  ## Variable ##

  def variable_defaults() do
    %Variable{
      title: "Variable#{unique_int()}",
      slug: "variable_#{unique_int()}",
    }
  end

  def detail_variable_deps() do
    decision = create_decision()
    detail_variable_deps(decision)
  end

  def detail_variable_deps(%Decision{} = decision)  do
    create_option_detail(decision, %{format: :integer})
  end

  def create_detail_variable() do
    decision = create_decision()
    create_detail_variable(decision)
  end

  def create_detail_variable(%Decision{} = decision) do
    create_detail_variable(decision, %{})
  end

  def create_detail_variable(%Decision{} = decision, %OptionDetail{} = option_detail) do
    create_detail_variable(decision, %{option_detail: option_detail})
  end

  def create_detail_variable(%Decision{} = decision, %{} = overrides) do
    deps = decision |> detail_variable_deps()
    values = deps |> Map.put(:method, :sum_selected) |> Map.merge(overrides)
    variable = insert(variable_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:variable, variable)
  end

  def filter_variable_deps() do
    decision = create_decision()
    filter_variable_deps(decision)
  end

  def filter_variable_deps(%Decision{} = decision) do
    create_option_category_filter(decision)
  end

  def create_filter_variable() do
    decision = create_decision()
    create_filter_variable(decision)
  end

  def create_filter_variable(%Decision{} = decision, overrides \\ %{}) do
    deps = decision |> filter_variable_deps()
    values = deps |> Map.put(:method, :count_selected) |> Map.merge(overrides)
    variable = insert(variable_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:variable, variable)
  end

  def fixed_variable_deps() do
    decision = create_decision()
    fixed_variable_deps(decision)
  end

  def fixed_variable_deps(%Decision{} = decision) do
    %{decision: decision} # no deps
  end

  def create_fixed_variable() do
    decision = create_decision()
    create_fixed_variable(decision)
  end

  def create_fixed_variable(%Decision{} = decision, overrides \\ %{}) do
    deps = decision |> fixed_variable_deps()
    values = deps |> Map.put(:method, :fixed)
      |> Map.put(:value, Enum.random(1..100) / 10)
      |> Map.merge(overrides)
    variable = insert(variable_defaults(), values)
    values |> Map.take(Map.keys(deps)) |> Map.put(:variable, variable)
  end

  def create_variable_without_deps(%Decision{} = decision, %{} = values) do
    values = Map.put(values, :decision, decision)
    insert(variable_defaults(), values)
  end

  def delete_variable(id) do
    Variable |> do_delete_all(id)
  end


end
