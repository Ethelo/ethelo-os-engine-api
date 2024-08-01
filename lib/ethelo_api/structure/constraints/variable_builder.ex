defmodule EtheloApi.Structure.VariableBuilder do
  @moduledoc """
  Used to suggest possible Variables based on OptionDetails and OptionFilters configured on a Decision.
  """

  alias EtheloApi.Structure.OptionDetail
  alias EtheloApi.Structure.OptionFilter
  alias EtheloApi.Structure.Variable
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.SuggestionMatcher
  alias EtheloApi.Structure.ExpressionParser
  import EtheloApi.Helpers.ExportHelper

  @doc """
  Populates suggested Variables

  ## Examples

      iex> ensure_all_valid_variables(decision)
      {:ok, nil}

      iex> ensure_all_valid_variables(decision)
      {:error, nil}

  """
  def ensure_all_valid_variables(decision_id) when is_integer(decision_id) do
    Structure.get_decision(decision_id) |> ensure_all_valid_variables
  end

  def ensure_all_valid_variables(%Decision{} = decision) do
    # ensure Calculations are properly linked up with Variables
    Structure.list_calculations(decision)
    |> Enum.each(fn calculation ->
      parsed = ExpressionParser.parse(calculation.expression)
      Structure.update_calculation(calculation, %{variables: parsed.variables})
    end)

    option_details = Structure.list_option_details(decision)
    option_filters = Structure.list_option_filters(decision)

    valid_variables = valid_variables(option_details, option_filters)

    variable_updates(valid_variables)
    |> update_existing_variables(decision)

    suggested_variables(valid_variables)
    |> create_suggested_variables(decision)

    {:ok, true}
  end

  def valid_variables(option_details, option_filters)
      when is_list(option_details) and is_list(option_filters) do
    variables = detail_variables(option_details) ++ filter_variables(option_filters)
    add_ids(variables)
  end

  # Variables that do not exist yet
  def suggested_variables(option_details, option_filters)
      when is_list(option_details) and is_list(option_filters) do
    valid_variables(option_details, option_filters)
    |> Enum.reject(&Map.get(&1, :id, false))
  end

  def suggested_variables(valid_variables) do
    valid_variables |> Enum.reject(&Map.get(&1, :id, false))
  end

  # Variables that do not exist yet
  def variable_updates(%OptionDetail{} = option_detail, option_filters),
    do: valid_variables([option_detail], option_filters)

  def variable_updates(option_details, %OptionFilter{} = option_filter),
    do: valid_variables(option_details, [option_filter])

  def variable_updates(option_details, option_filters)
      when is_list(option_details) and is_list(option_filters) do
    valid_variables(option_details, option_filters) |> variable_updates()
  end

  def variable_updates(valid_variables) do
    valid_variables |> Enum.filter(&Map.get(&1, :id, false))
  end

  def update_existing_variables(updates, decision) do
    variables_by_id = Structure.list_variables(decision) |> group_by_id()

    updates
    |> Enum.map(fn updated ->
      existing = Map.get(variables_by_id, updated.id)

      attrs =
        Map.from_struct(updated)
        |> clean_map
        |> Map.put(:slug, nil)
        |> Map.delete(:id)

      Structure.update_used_variable(existing, attrs)
    end)
  end

  def create_suggested_variables(variables, %Decision{} = decision) do
    variables
    |> Enum.map(&Map.from_struct/1)
    |> Enum.map(&add_slug/1)
    |> Enum.map(&Structure.create_variable(&1, decision, false))
  end

  def add_ids([]), do: []

  def add_ids(suggested) do
    first = suggested |> hd()

    SuggestionMatcher.add_existing_ids(
      suggested,
      Structure.list_variables(first.decision_id),
      &matches?/2
    )
  end

  defp add_slug(%{slug: nil} = struct) do
    title = Map.get(struct, :title)
    Map.put(struct, :slug, UniqueSlug.string_to_slug(title))
  end

  defp add_slug(%{slug: _} = struct) do
    struct
  end

  def matches?(suggested, existing) do
    existing.option_detail_id == suggested.option_detail_id and
      existing.option_filter_id == suggested.option_filter_id and
      existing.method == suggested.method
  end

  def filter_variables([]), do: []

  def filter_variables(option_filters) do
    option_filters |> Enum.flat_map(&convert_to_filter_variables/1)
  end

  def convert_to_filter_variables(%OptionFilter{} = option_filter) do
    [
      build_filter_variable(
        :count_selected,
        "Count #{option_filter.title}",
        "count_#{option_filter.slug}",
        option_filter
      )
    ]
  end

  def build_filter_variable(method, title, slug, option_filter) do
    %Variable{
      method: method,
      option_filter_id: option_filter.id,
      title: title,
      slug: Variable.slugger(slug),
      decision_id: option_filter.decision_id
    }
  end

  def detail_variables([]), do: []

  def detail_variables(option_details) do
    option_details |> Enum.flat_map(&convert_to_detail_variables/1)
  end

  def convert_to_detail_variables(%OptionDetail{format: format} = option_detail)
      when format in [:float, :integer] do
    [
      build_detail_variable(
        :sum_selected,
        "Total #{option_detail.title}",
        "total_#{option_detail.slug}",
        option_detail
      ),
      build_detail_variable(
        :mean_selected,
        "Avg #{option_detail.title}",
        "avg_#{option_detail.slug}",
        option_detail
      )
    ]
  end

  def convert_to_detail_variables(_), do: []

  def build_detail_variable(method, title, slug, option_detail) do
    %Variable{
      method: method,
      option_detail_id: option_detail.id,
      title: title,
      slug: Variable.slugger(slug),
      decision_id: option_detail.decision_id
    }
  end
end
