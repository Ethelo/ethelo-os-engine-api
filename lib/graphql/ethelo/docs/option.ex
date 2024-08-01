defmodule GraphQL.EtheloApi.Docs.Option do
  @moduledoc """
  assemble query descriptions to use in graphql queries
  """
  alias EtheloApi.Structure.Docs.Option, as: OptionDocs
  alias EtheloApi.Structure.Docs.OptionDetailValue, as: OptionDetailValueDocs
  alias EtheloApi.Structure.Docs.OptionFilter, as: OptionFilterDocs

  alias GraphQL.DocBuilder

  defp sample1() do
    Map.get(OptionDocs.examples(), "Sample 1")
  end

  defp sample2() do
    Map.get(OptionDocs.examples(), "Sample 2")
  end

  defp filter_sample1() do
    Map.get(OptionFilterDocs.examples(), "Sample 1")
  end

  defp update1() do
    OptionDocs.examples() |> Map.get("Update 1") |> Map.put(:id, sample1().id)
  end

  defp input_fields() do
    [:slug, :info, :enabled, :title, :results_title, :option_category_id, :sort, :determinative]
  end

  defp object_name() do
    "option"
  end

  def list() do
    request = sample1()
    responses = [sample1(), sample2()]
    DocBuilder.list("options", request, responses, [:decision_id])
  end

  def list_by_detail_value() do
    request = filter_sample1() |> Map.put(:enabled_only, true)
    param_fields = [:decision_id, :match_value, :match_mode, :option_detail_id, :enabled_only]
    responses = [sample1(), sample2()]
    comment = "List Options matching OptionDetailValue. See OptionFilter for descriptions of matchValue and matchMode."
    DocBuilder.list("optionsByDetailValue", request, responses, param_fields, comment)
  end

  def list_by_category() do
    request = sample1()
    param_fields = [:decision_id, :option_category_id]
    responses = [sample1(), sample2()]
    comment = "List Options matching OptionCategory."
    DocBuilder.list("optionsByCategory", request, responses, param_fields, comment)
  end

  def list_by_filter() do
    sample = filter_sample1()
    request = %{
      decision_id: sample.decision_id,
      option_filter_id: sample.id,
      enabled_only: true,
    }
    param_fields = [:decision_id, :option_filter_id, :enabled_only]
    responses = [sample1(), sample2()]
    comment = "List Options matching specified filter."
    DocBuilder.list("optionsByFilter", request, responses, param_fields, comment)
  end

  def get() do
    request = sample1()
    response = sample1()
    param_fields = [:decision_id, :id]
    DocBuilder.get(object_name(), request, response, param_fields)
  end

  def create() do
    query_field = "createOption"
    request = sample1()
    response = sample1()

    DocBuilder.create(query_field, request, response, object_name(), input_fields())
  end

  def update() do
    query_field = "updateOption"
    request = update1()
    response = update1()
    DocBuilder.update(query_field, request, response, object_name(), input_fields())
  end

  def delete() do
    query_field = "deleteOption"
    request = sample1()
    comment = "All associated OptionValues will also be removed."

    DocBuilder.delete(query_field, request, object_name(), comment)
  end

  defp odv_sample1() do
    Map.get(OptionDetailValueDocs.examples, "Sample 1")
  end

  defp odv_update() do
    Map.get(OptionDetailValueDocs.examples, "Update 1")
  end

  def create_odv() do
    query_field = "createOptionDetailValue"
    request = odv_sample1()
    response = odv_sample1()
    param_fields = [:decision_id, :option_id, :option_detail_id, :value]

    DocBuilder.create_params(query_field, request, response, "OptionDetailValue", param_fields)
  end

  def update_odv() do
    query_field = "updateOptionDetailValue"
    request = odv_update()
    response = odv_update()
    param_fields = [:decision_id, :option_id, :option_detail_id, :value]

    DocBuilder.update_params(query_field, request, response, "OptionDetailValue", param_fields)
  end

  def delete_odv() do
    query_field = "deleteOptionDetailValue"
    request = odv_sample1()
    param_fields = [:decision_id, :option_id, :option_detail_id, :value]

    DocBuilder.delete_params(query_field, request, object_name(), param_fields, "")
  end
end
