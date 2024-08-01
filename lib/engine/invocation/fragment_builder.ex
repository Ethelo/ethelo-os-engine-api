defmodule Engine.Invocation.FragmentBuilder do
  @moduledoc """
  Convert variables into reusuable fragments that will be applied to
  constraints and displays
  """

  import Engine.Invocation.Slugger
  alias Engine.Invocation.ScoringData
  alias EtheloApi.Helpers.ExportHelper

  def fragments_segment(%ScoringData{} = decision_json_data) do
    filters_by_id = ExportHelper.group_by_id(decision_json_data.option_filters)
    details_by_id = ExportHelper.group_by_id(decision_json_data.option_details)
    options_by_filter = decision_json_data.option_ids_by_filter_id

    values =
      Enum.map(decision_json_data.variables, fn variable ->
        code =
          case variable.method do
            :count_selected -> count_selected_code(variable, filters_by_id)
            :count_all -> count_all_code(variable, options_by_filter)
            :sum_selected -> sum_selected_code(variable, details_by_id)
            :sum_all -> loop_code("sum_all", variable, details_by_id)
            :mean_all -> loop_code("mean_all", variable, details_by_id)
            :mean_selected -> loop_code("mean", variable, details_by_id)
          end

        %{name: variable.slug, code: code}
      end)

    %{fragments: values}
  end

  def loop_code(loop_method, variable, details) do
    details
    |> Map.get(variable.option_detail_id)
    |> detail_value_slug()
    |> (fn slug -> "#{loop_method}[i in x]{$#{slug}[i]}" end).()
  end

  def sum_selected_code(variable, details) do
    details
    |> Map.get(variable.option_detail_id)
    |> detail_value_slug()
    |> (fn slug -> "$#{slug}" end).()
  end

  def count_all_code(variable, filter_options) do
    filter_options
    |> Map.get(variable.option_filter_id, [])
    |> Enum.count()
    |> to_string()
  end

  def count_selected_code(variable, filters) do
    filters
    |> Map.get(variable.option_filter_id)
    |> filter_group_slug()
    |> (fn slug -> "$#{slug}" end).()
  end
end
