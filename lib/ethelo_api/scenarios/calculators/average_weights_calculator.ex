defmodule EtheloApi.Scenarios.Calculators.AverageWeightsCalculator do
  alias EtheloApi.Invocation.WeightsJson

  def average_weights(_, %{criteria: %{apply_participant_weights: false}} = assocs) do
    %{average_weight: WeightsJson.get_record_weight(assocs.criteria, 100)}
  end

  def average_weights(_, %{option_category: %{apply_participant_weights: false}} = assocs) do
    %{average_weight: WeightsJson.get_record_weight(assocs.option_category, 100)}
  end

  def average_weights(%{} = import_data, %{criteria: criteria}) do
    import_data.criteria_weights_by_criteria
    |> Map.get(criteria.id, [])
    |> extract_and_average(criteria, import_data)
  end

  def average_weights(%{} = import_data, %{option_category: option_category}) do
    import_data.option_category_weights_by_oc
    |> Map.get(option_category.id, [])
    |> extract_and_average(option_category, import_data)
  end

  def average_weights(_, _), do: %{average_weight: nil}

  def extract_and_average(weight_list, default_record, import_data) do
    default_weight = WeightsJson.get_record_weight(default_record, 100)

    weights =
      weight_list
      |> Enum.map(fn weight_vote ->
        WeightsJson.get_record_weight(weight_vote, default_weight)
      end)

    with_default = length(import_data.participants) - length(weights)

    average =
      case weights do
        [] ->
          default_weight

        _ ->
          (Enum.sum(weights) + with_default * default_weight) / (length(weights) + with_default)
      end

    %{average_weight: average}
  end
end
