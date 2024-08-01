defmodule EtheloApi.Constraints.FilterData do
  @moduledoc """
  Used to suggest possible filters based on details configured on a decision.
  """

  require Timex
  alias EtheloApi.Structure.OptionDetail
  alias EtheloApi.Structure.OptionCategory
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure
  alias EtheloApi.Constraints.FilterData

  import EtheloApi.Helpers.ExportHelper

  defstruct [
    :decision,
    :option_detail_data,
    :option_category_data,
    :option_filters,
    :option_filters_by_id,
    :missing_filters,
    :updated_filters,
    :created_filters,
    :changed_filters
  ]

  @doc """
  loads option filters necessary data into a struct to be passed around
  This version is expected to be built upon by other methods

  ## Examples

      iex> FilterData.initialize(decision)
      %FilterData{}

  """
  def initialize(%Decision{} = decision) do
    option_filters = Structure.list_option_filters(decision.id)

    %FilterData{
      decision: decision,
      option_filters: option_filters,
      option_filters_by_id: option_filters |> group_by_id()
    }
  end

  def initialize(decision_id) when is_integer(decision_id) do
    Structure.get_decision(decision_id) |> initialize()
  end

  def initialize(_), do: raise(ArgumentError, message: "you must supply a Decision")

  def initialize_all(decision) do
    data = initialize_details(decision)
    Map.put(data, :option_category_data, get_option_category_data(data.decision))
  end

  def initialize_details(decision) do
    data = initialize(decision)
    Map.put(data, :option_detail_data, get_option_detail_data(data.decision))
  end

  def initialize_option_detail(%OptionDetail{} = option_detail, decision) do
    data = initialize(decision)

    Map.put(
      data,
      :option_detail_data,
      get_option_detail_data(data.decision, %{id: option_detail.id})
    )
  end

  def initialize_categories(decision) do
    data = initialize(decision)
    option_category_data = get_option_category_data(data)
    Map.put(data, :option_category_data, option_category_data)
  end

  def initialize_option_category(%OptionCategory{} = option_category, decision) do
    data = initialize(decision)
    oc_data = [option_category |> clean_map()]
    Map.put(data, :option_category_data, oc_data)
  end

  defp get_option_category_data(decision) do
    filters = %{} |> Map.put(:distinct, true)
    Structure.list_option_categories(decision, filters, [:id, :slug, :title])
  end

  # don't autocreate or suggest for any non boolean option details
  defp get_option_detail_data(decision, filters \\ %{}) do
    filters = filters |> Map.put(:distinct, true) |> Map.put(:format, :boolean)
    Structure.list_option_details(decision, filters, [:id, :slug, :title, :format])
  end
end
