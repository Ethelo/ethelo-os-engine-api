defmodule EtheloApi.Structure.FilterData do
  @moduledoc """
  Used to suggest possible OptionFilters based on details configured on a Decision.
  """

  alias EtheloApi.Structure.OptionDetail
  alias EtheloApi.Structure.OptionCategory
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure
  alias EtheloApi.Structure.FilterData

  import EtheloApi.Helpers.ExportHelper

  @enforce_keys [
    :decision,
    :option_filters,
    :option_filters_by_id
  ]

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

  @type t :: %__MODULE__{
          decision: struct(),
          option_detail_data: list(map) | nil,
          option_category_data: list(map) | nil,
          option_filters: list(map),
          option_filters_by_id: map(),
          missing_filters: list(map) | nil,
          updated_filters: list(map) | nil,
          created_filters: list(map) | nil,
          changed_filters: list(map) | nil
        }

  @doc """
  loads OptionFilters necessary data into a struct to be passed around
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
    modifiers = %{} |> Map.put(:distinct, true)
    Structure.list_option_categories(decision, modifiers, [:id, :slug, :title])
  end

  # don't autocreate or suggest for any non boolean OptionDetails
  defp get_option_detail_data(decision, modifiers \\ %{}) do
    modifiers = modifiers |> Map.put(:distinct, true) |> Map.put(:format, :boolean)
    Structure.list_option_details(decision, modifiers, [:id, :slug, :title, :format])
  end
end
