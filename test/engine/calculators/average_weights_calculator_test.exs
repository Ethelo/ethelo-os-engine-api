defmodule Engine.Scenarios.AverageWeightsCalculatorTest do
  @moduledoc """
  Validations and basic access for ScoringData
  """
  use EtheloApi.DataCase
  import EtheloApi.Helpers.ExportHelper

  alias Engine.Invocation.ScoringData
  alias Engine.Scenarios.Calculators.AverageWeightsCalculator

    test "average criteria weights are calculated" do
      scoring_data = %ScoringData{
        criteria_weights: [
          %{criteria_id: 1, participant_id: 2, weighting: 10},
          %{criteria_id: 1, participant_id: 1, weighting: 25},
          %{criteria_id: 2, participant_id: 1, weighting: 40},
        ],
        criterias: [
          %{apply_participant_weights: true, id: 1, weighting: 50},
          %{apply_participant_weights: false, id: 2, weighting: 47},
        ],
        participants: [
          %{id: 1, weighting: Decimal.from_float(1.00)},
          %{id: 2, weighting: Decimal.from_float(1.00)},
          %{id: 3, weighting: Decimal.from_float(1.00)},
        ],
      }

      scoring_data =
        scoring_data
        |> Map.put(:criteria_weights_by_criteria, scoring_data.criteria_weights |> group_by_criteria())

      [criteria1, criteria2] = scoring_data.criterias

      # participant weights applied
      # average of two weights + 1 default from 1 non voter
      result = AverageWeightsCalculator.average_weights(scoring_data, %{criteria: criteria1})
      assert result ==  %{average_weight: 28.333333333333332}

      # participant weights not applied
      result = AverageWeightsCalculator.average_weights(scoring_data, %{criteria: criteria2})
      assert result == %{average_weight: 47}
    end

    test "average option category weights are calculated" do
      scoring_data = %ScoringData{
        option_categories: [
          %{id: 1, weighting: 50, apply_participant_weights: true},
          %{id: 2, weighting: 38, apply_participant_weights: false},
        ],
        option_category_weights: [
          %{option_category_id: 1, participant_id: 1, weighting: 5},
          %{option_category_id: 1, participant_id: 2, weighting: 10},
          %{option_category_id: 2, participant_id: 1, weighting: 3},
        ],
        participants: [
          %{id: 1, weighting: Decimal.from_float(1.00)},
          %{id: 2, weighting: Decimal.from_float(1.00)},
          %{id: 3, weighting: Decimal.from_float(1.00)},
        ],
      }
      scoring_data =
        scoring_data
        |> Map.put(:option_category_weights_by_oc, scoring_data.option_category_weights |> group_by_option_category())

      [option_category1, option_category2] = scoring_data.option_categories

      result1 = AverageWeightsCalculator.average_weights(scoring_data, %{option_category: option_category1})
       # average of two weights + 1 default from 1 non voter
      assert result1 == %{average_weight: 21.666666666666668}

      result2 = AverageWeightsCalculator.average_weights(scoring_data, %{option_category: option_category2})
      assert result2 == %{average_weight: 38} # always the default weight
    end

end
