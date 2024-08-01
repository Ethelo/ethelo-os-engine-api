defmodule Engine.Invocation.OptionBuilder do
  @moduledoc """
  Convert options and their associated detail values to invocation json
  Also creates detail values based on inclusion in filter groups
  """

  import Engine.Invocation.Slugger
  import EtheloApi.Constraints.ValueParser
  alias Engine.Invocation.ScoringData
  alias EtheloApi.Helpers.ExportHelper

  def options_segment(%ScoringData{} = decision_json_data) do
    options_by_filter = decision_json_data.option_ids_by_filter_slug
    odvs_by_option = ExportHelper.group_by_option(decision_json_data.option_detail_values)

    values =
      Enum.map(decision_json_data.options, fn option ->
        category_details = category_details(option, decision_json_data.option_categories)

        value_details =
          odvs_by_option
          |> Map.get(option.id, [])
          |> value_details(decision_json_data.option_details)

        filter_details = filter_details(option, options_by_filter)

        %{
          name: option.slug,
          determinative: option.determinative,
          details: category_details ++ value_details ++ filter_details
        }
      end)

    %{options: values}
  end

  def category_details(option, option_categories) do
    option_categories
    |> Enum.filter(fn option_category -> option.option_category_id == option_category.id end)
    |> Enum.map(fn option_category ->
      %{name: "C" <> option_category.slug, value: 1}
    end)
  end

  def value_details(odvs, option_details) when is_list(odvs) do
    odv_values = values_by_detail_id(odvs)

    option_details
    |> Enum.filter(fn option_detail -> option_detail.format in [:integer, :float] end)
    |> Enum.map(fn option_detail ->
      odv_value = Map.get(odv_values, option_detail.id, nil)
      str_value = to_matchable_string(odv_value, option_detail.format)

      # should invalid values be skipped or set to 0 before sending to engine?
      float_val =
        case str_value do
          {:ok, value} -> to_float(value)
          _ -> 0
        end

      %{
        name: detail_value_slug(option_detail.slug),
        value: float_val
      }
    end)
  end

  def value_details(odv, option_details) do
    value_details([odv], option_details)
  end

  defp values_by_detail_id(odvs) do
    odvs
    |> Enum.map(fn odv -> {odv.option_detail_id, odv.value} end)
    |> Enum.into(%{})
  end

  def filter_details(%{} = option, %{} = options_by_filter) do
    Enum.map(options_by_filter, fn {slug, option_ids} ->
      value = if option.id in option_ids, do: 1, else: 0
      %{name: filter_group_slug(slug), value: value}
    end)
  end

  # should always be valid because we're getting it from matchable string
  defp to_float(value) do
    case Float.parse(value) do
      {number, _} ->
        if Float.floor(number) == Float.ceil(number) do
          Kernel.trunc(number)
        else
          number
        end

      :error ->
        0
    end
  end
end
