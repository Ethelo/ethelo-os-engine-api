defmodule EtheloApi.Structure do
  @moduledoc """
  The boundary for the Structure system.

  All access to update database values go through this class.
  To keep code files small, the actual methods are in the /queries folder
  and are linked with defdelegate
  """

  alias EtheloApi.Structure.Queries.Calculation
  alias EtheloApi.Structure.Queries.Constraint
  alias EtheloApi.Structure.Queries.Criteria
  alias EtheloApi.Structure.Queries.Decision
  alias EtheloApi.Structure.Queries.Option
  alias EtheloApi.Structure.Queries.OptionCategory
  alias EtheloApi.Structure.Queries.OptionDetail
  alias EtheloApi.Structure.Queries.OptionDetailValue
  alias EtheloApi.Structure.Queries.OptionFilter
  alias EtheloApi.Constraints.FilterBuilder
  alias EtheloApi.Structure.Queries.Variable
  alias EtheloApi.Constraints.VariableBuilder

  def maybe_update_structure_hash({:error, _} = result, _, _), do: result
  def maybe_update_structure_hash(result, _, %{} = changes) when map_size(changes) == 0, do: result
  def maybe_update_structure_hash(result, decision_id, %{}) do
    update_decision_hash(decision_id)
    result
  end

  def maybe_update_decision_influent_hash({:error, _} = result, _, _), do: result
  def maybe_update_decision_influent_hash(result, _, %{} = changes) when map_size(changes) == 0 do
     result
  end
  def maybe_update_decision_influent_hash(result, decision_id, %{}) do
    update_decision_hash(decision_id)
    result
  end

  def maybe_update_decision_weighting_hash({:error, _} = result, _, _), do: result
  def maybe_update_decision_weighting_hash(result, _, %{} = changes) when map_size(changes) == 0 do
     result
  end
  def maybe_update_decision_weighting_hash(result, decision_id, %{}) do
    update_decision_hash(decision_id)
    result
  end

  @doc """
  Populates suggested filters and variables used for 'automatic' constraints
  Currently if an OptionCategory is flagged as 'xor' an automatic constraint is added
  So all OptionCategory filters and variables are added here.

  ## Examples

      iex> ensure_filters_and_variables(updated_record, decision_id, changes)
      {:ok, nil}

      iex> ensure_filters_and_variables(updated_record, decision_id, changes)
      {:error, nil}

  """
  def ensure_filters_and_vars({:error, _} = result, _, _), do: result
  def ensure_filters_and_vars({:ok, _} = result, _, %{} = changes) when map_size(changes) == 0 do
    result
  end
  def ensure_filters_and_vars(result, decision_id, %{}) do
    ensure_filters_and_vars(decision_id)
    result
  end

  def ensure_filters_and_vars(decision_id) do
    FilterBuilder.ensure_all_valid_filters(decision_id)
    VariableBuilder.ensure_all_valid_variables(decision_id)
  end

  defdelegate preloaded_assoc(record, association), to: EtheloApi.Helpers.BatchHelper
  defdelegate associated_id(record, association), to: EtheloApi.Helpers.BatchHelper

  defdelegate list_decisions(filters \\ %{}), to: Decision
  defdelegate get_decision(id), to: Decision
  defdelegate match_decision(filters), to: Decision
  defdelegate create_decision(attrs), to: Decision
  defdelegate ensure_default_associations(decision), to: Decision
  defdelegate update_decision(decision, attrs), to: Decision
  defdelegate delete_decision(decision), to: Decision
  defdelegate update_decision_hash(decision), to: Decision
  defdelegate update_decision_influent_hash(decision), to: Decision
  defdelegate update_decision_weighting_hash(decision), to: Decision

  defdelegate list_option_details(decision_id, filters \\ %{}, fields \\ nil), to: OptionDetail
  defdelegate match_option_details(filters, decision), to: OptionDetail
  defdelegate get_option_detail(id, decision), to: OptionDetail
  defdelegate create_option_detail(decision, attrs, post_process \\ true), to: OptionDetail
  defdelegate update_option_detail(option_detail, attrs, post_process \\ true), to: OptionDetail
  defdelegate delete_option_detail(option_detail, decision_id), to: OptionDetail

  defdelegate list_options(decision_id, filters \\ %{}, fields \\ nil), to: Option
  defdelegate list_options_by_ids(option_ids, decision_id), to: Option
  defdelegate match_options(filters, decision), to: Option
  defdelegate get_option(id, decision), to: Option
  defdelegate create_option(decision, attrs), to: Option
  defdelegate update_option(option, attrs), to: Option
  defdelegate delete_option(option, decision_id), to: Option

  defdelegate list_option_detail_values(decision, filters \\ %{}, fields \\ nil), to: OptionDetailValue
  defdelegate match_option_detail_values(filters, decision), to: OptionDetailValue
  defdelegate get_option_detail_value(option_id, option_detail_id, decision_id), to: OptionDetailValue
  defdelegate get_option_detail_value(attrs, decision_id), to: OptionDetailValue
  defdelegate upsert_option_detail_value(decision, attrs), to: OptionDetailValue
  defdelegate delete_option_detail_value(option_detail_value, decision_id), to: OptionDetailValue

  defdelegate list_criterias(decision_id, filters \\ %{}), to: Criteria
  defdelegate match_criterias(filters, decision), to: Criteria
  defdelegate get_criteria(id, decision), to: Criteria
  defdelegate create_criteria(decision, attrs), to: Criteria
  defdelegate update_criteria(criteria, attrs), to: Criteria
  defdelegate delete_criteria(criteria, decision_id), to: Criteria

  defdelegate list_option_categories(decision_id, filters \\ %{}, fields \\ nil), to: OptionCategory
  defdelegate match_option_categories(filters, decision), to: OptionCategory
  defdelegate get_option_category(id, decision), to: OptionCategory
  defdelegate get_default_option_category(decision), to: OptionCategory
  defdelegate create_option_category(decision, attrs, post_process \\ true), to: OptionCategory
  defdelegate update_option_category(option_category, attrs, post_process \\ true), to: OptionCategory
  defdelegate delete_option_category(option_category, decision_id), to: OptionCategory

  defdelegate list_option_filters(decision_id, filters \\ %{}), to: OptionFilter
  defdelegate match_option_filters(filters, decision), to: OptionFilter
  defdelegate get_option_filter(id, decision), to: OptionFilter
  defdelegate create_option_filter(decision, attrs, post_process \\ true), to: OptionFilter
  defdelegate update_option_filter(option_filter, attrs, post_process \\ true), to: OptionFilter
  defdelegate delete_option_filter(option_filter, decision_id), to: OptionFilter
  defdelegate all_options_for_all_filters(decision_ids), to: OptionFilter
  defdelegate all_options_for_all_filters(batch_info, decision_ids), to: OptionFilter
  defdelegate option_ids_matching_filter(option_filter, enabled_only \\ false), to: EtheloApi.Constraints.FilterOptions
  defdelegate option_ids_matching_filter_data(scoring_data), to: EtheloApi.Constraints.FilterOptions

  defdelegate list_variables(decision_id, filters \\ %{}), to: Variable
  defdelegate match_variables(filters, decision), to: Variable
  defdelegate suggested_variables(decision_id), to: Variable
  defdelegate get_variable(id, decision), to: Variable
  defdelegate create_variable(decision, attrs, post_process \\ true), to: Variable
  defdelegate update_variable(variable, attrs), to: Variable
  defdelegate update_used_variable(variable, attrs), to: Variable
  defdelegate delete_variable(variable, decision_id), to: Variable

  defdelegate list_calculations(decision_id, filters \\ %{}), to: Calculation
  defdelegate match_calculations(filters, decision), to: Calculation
  defdelegate get_calculation(id, decision), to: Calculation
  defdelegate create_calculation(decision, attrs), to: Calculation
  defdelegate update_calculation(calculation, attrs), to: Calculation
  defdelegate delete_calculation(calculation, decision_id), to: Calculation
  defdelegate replace_variable_in_calculation(calculation, old, new), to: Calculation

  defdelegate list_constraints(decision_id, filters \\ %{}), to: Constraint
  defdelegate match_constraints(filters, decision), to: Constraint
  defdelegate get_constraint(id, decision), to: Constraint
  defdelegate create_constraint(decision, attrs), to: Constraint
  defdelegate update_constraint(constraint, attrs), to: Constraint
  defdelegate delete_constraint(constraint, decision_id), to: Constraint

end
