defmodule Engine.Scenarios.HistogramCalculatorTest do
  @moduledoc """
  Validations and basic access for ScoringData
  """
  use EtheloApi.DataCase
  import EtheloApi.Helpers.ExportHelper

  alias Engine.Invocation.ScoringData
  alias Engine.Scenarios.Calculators.HistogramCalculator

    def range_vote_data(ocrvs, support_only) do
      scoring_data = %ScoringData{
        option_category_range_votes: ocrvs,
        bin_votes: [],
        criterias: [
          %{id: 1}
        ],
        options: [
          %{id: 1, option_category_id: 1 },
          %{id: 2, option_category_id: 1 },
          %{id: 3, option_category_id: 1 },
          %{id: 4, option_category_id: 1 },
          %{id: 5, option_category_id: 1 },

          %{id: 6, option_category_id: 2 },
          %{id: 7, option_category_id: 2 },
          %{id: 8, option_category_id: 2 },
          %{id: 9, option_category_id: 2 },
          %{id: 10, option_category_id: 2 },

          %{id: 11, option_category_id: 3 },

        ],
        option_categories: [
          %{ id: 1, scoring_mode: :triangle, triangle_base: 5, primary_detail_id: 1},
          %{ id: 2, scoring_mode: :rectangle, primary_detail_id: 1},
          %{ id: 3, scoring_mode: :none, }
        ],
        option_details: [
          %{id: 1, format: :float},
        ],
        option_detail_values: [
          %{option_id: 1, option_detail_id: 1, value: "1"},
          %{option_id: 2, option_detail_id: 1, value: "2"},
          %{option_id: 3, option_detail_id: 1, value: "3"},
          %{option_id: 4, option_detail_id: 1, value: "4"},
          %{option_id: 5, option_detail_id: 1, value: "5"},
          %{option_id: 6, option_detail_id: 1, value: "1"},
          %{option_id: 7, option_detail_id: 1, value: "2"},
          %{option_id: 8, option_detail_id: 1, value: "3"},
          %{option_id: 9, option_detail_id: 1, value: "4"},
          %{option_id: 10, option_detail_id: 1, value: "5"},
          %{option_id: 11, option_detail_id: 1, value: "5"},

        ],
        participants: [
          %{id: 1, weighting: Decimal.from_float(1.00)},
          %{id: 2, weighting: Decimal.from_float(1.00)},
          %{id: 3, weighting: Decimal.from_float(1.00)},
          %{id: 4, weighting: Decimal.from_float(1.00)},
          %{id: 5, weighting: Decimal.from_float(1.00)},
        ],
        scenario_config: %{
          bins: 5, support_only: support_only,
        }
      }

      scoring_data
        |> Map.put( :bin_votes_by_option, scoring_data.bin_votes |> group_by_option())
        |> Map.put( :option_categories_by_id, scoring_data.option_categories |> group_by_id())
        |> Map.put( :options_by_oc, scoring_data.options |> group_by_option_category())
        |> Map.put( :options_by_id, scoring_data.options |> group_by_id())
        |> Map.put( :option_details_by_id, scoring_data.option_details |> group_by_id())
        |> Map.put( :option_category_range_votes_by_oc, scoring_data.option_category_range_votes |> group_by_option_category() )
    end

    test "histograms with bin votes" do
      scoring_data = %ScoringData{
        options: [
          %{id: 1, option_category_id: 1 },
        ],
        option_categories: [
          %{ id: 1, scoring_mode: :none}
        ],
        criterias: [
          %{id: 1}
        ],
        participants: [
          %{id: 1, weighting: Decimal.from_float(1.00)},
          %{id: 2, weighting: Decimal.from_float(1.00)},
          %{id: 3, weighting: Decimal.from_float(1.00)},
          %{id: 4, weighting: Decimal.from_float(1.00)},
          %{id: 5, weighting: Decimal.from_float(1.00)},
        ],
        bin_votes: [
          %{option_id: 1, criteria_id: 1, participant_id: 1, bin: 1 },
          %{option_id: 1, criteria_id: 1, participant_id: 2, bin: 2 },
          %{option_id: 1, criteria_id: 1, participant_id: 3, bin: 2 },
          %{option_id: 1, criteria_id: 1, participant_id: 4, bin: 4 },
          %{option_id: 1, criteria_id: 1, participant_id: 5, bin: 5 },
        ],
        scenario_config: %{
          bins: 5,
        }
      }

      scoring_data =
        scoring_data
        |> Map.put( :bin_votes_by_option, scoring_data.bin_votes |> group_by_option())
        |> Map.put( :option_categories_by_id, scoring_data.option_categories |> group_by_id())

      criteria = scoring_data.criterias |> List.first()
      option = scoring_data.options |> List.first()

      result = scoring_data |> HistogramCalculator.bin_vote_histogram(%{option: option, criteria: criteria})
      assert [1, 2, 0, 1, 1] == result

      result2 = scoring_data |> HistogramCalculator.bin_vote_histogram(%{option: option})
      assert [1, 2, 0, 1, 1] == result2
    end

    test "histogram with triangle slider votes and support only off " do
      #triangle is oc 1 and options 1-5
      # should be identical with support on or off

      option_category_range_votes =  [
        %{high_option_id: 3, low_option_id: 3, option_category_id: 1, participant_id: 1},
        %{high_option_id: 5, low_option_id: 5, option_category_id: 1, participant_id: 2},
        %{high_option_id: 1, low_option_id: 1, option_category_id: 1, participant_id: 3},
      ]

      scoring_data = range_vote_data(option_category_range_votes, false)

      [option1, option2, option3, option4, option5 | _] = scoring_data.options_by_oc[1]
      criteria = scoring_data.criterias |> List.first

      result_option_crit = scoring_data |> HistogramCalculator.bin_vote_histogram(%{option: option1, criteria: criteria})
      assert [0, 0, 0, 0, 0] == result_option_crit

      option1_histogram = scoring_data |> HistogramCalculator.bin_vote_histogram(%{option: option1})
      assert [1, 1, 0, 0, 1] == option1_histogram

      option1_spectrum = HistogramCalculator.vote_spectrum(option1_histogram)
      assert %{negative_votes: 2, neutral_votes: 0, positive_votes: 1} == option1_spectrum

      option2_histogram = scoring_data |> HistogramCalculator.bin_vote_histogram(%{option: option2})
      assert [1, 0, 2, 0, 0] == option2_histogram

      option2_spectrum = HistogramCalculator.vote_spectrum(option2_histogram)
      assert %{negative_votes: 1, neutral_votes: 2, positive_votes: 0} == option2_spectrum

      option3_histogram = scoring_data |> HistogramCalculator.bin_vote_histogram(%{option: option3})
      assert [0, 2, 0, 0, 1] == option3_histogram

      option3_spectrum = HistogramCalculator.vote_spectrum(option3_histogram)
      assert %{negative_votes: 2, neutral_votes: 0, positive_votes: 1} == option3_spectrum

      option4_histogram = scoring_data |> HistogramCalculator.bin_vote_histogram(%{option: option4})
      assert [1, 0, 2, 0, 0] == option4_histogram

      option4_spectrum = HistogramCalculator.vote_spectrum(option4_histogram)
      assert %{negative_votes: 1, neutral_votes: 2, positive_votes: 0} == option4_spectrum

      option5_histogram = scoring_data |> HistogramCalculator.bin_vote_histogram(%{option: option5})
      assert [1, 1, 0, 0, 1] == option5_histogram

      option5_spectrum = HistogramCalculator.vote_spectrum(option5_histogram)
      assert %{negative_votes: 2, neutral_votes: 0, positive_votes: 1} == option5_spectrum
    end

    test "histogram with triangle slider votes and support only on" do
      #triangle is oc 1 and options 1-5
      # should be identical with support on or off

      option_category_range_votes =  [
        %{high_option_id: 3, low_option_id: 3, option_category_id: 1, participant_id: 1},
        %{high_option_id: 5, low_option_id: 5, option_category_id: 1, participant_id: 2},
        %{high_option_id: 1, low_option_id: 1, option_category_id: 1, participant_id: 3},
      ]

      scoring_data = range_vote_data(option_category_range_votes, true)

      [option1, option2, option3, option4, option5 | _] = scoring_data.options_by_oc[1]
      criteria = scoring_data.criterias |> List.first

      result_option_crit = scoring_data |> HistogramCalculator.bin_vote_histogram(%{option: option1, criteria: criteria})
      assert [0, 0, 0, 0, 0] == result_option_crit

      option1_histogram = scoring_data |> HistogramCalculator.bin_vote_histogram(%{option: option1})
      assert [1, 1, 0, 0, 1] == option1_histogram

      option2_histogram = scoring_data |> HistogramCalculator.bin_vote_histogram(%{option: option2})
      assert [1, 0, 2, 0, 0] == option2_histogram

      option3_histogram = scoring_data |> HistogramCalculator.bin_vote_histogram(%{option: option3})
      assert [0, 2, 0, 0, 1] == option3_histogram

      option4_histogram = scoring_data |> HistogramCalculator.bin_vote_histogram(%{option: option4})
      assert [1, 0, 2, 0, 0] == option4_histogram

      option5_histogram = scoring_data |> HistogramCalculator.bin_vote_histogram(%{option: option5})
      assert [1, 1, 0, 0, 1] == option5_histogram


    end

    test "histogram with rectangle slider votes support on" do

      # rectangle is oc 2 and options 6-10
      # should be identical with support on or off

      option_category_range_votes =  [
        %{high_option_id: 6, low_option_id: 6, option_category_id: 2, participant_id: 1},
        %{high_option_id: 8, low_option_id: 8, option_category_id: 2, participant_id: 2},
        %{high_option_id: 10, low_option_id: 10, option_category_id: 2, participant_id: 3},
      ]
      scoring_data = range_vote_data(option_category_range_votes, true)

      [option6, option7, option8, option9, option10 | _] = scoring_data.options_by_oc[2]
      criteria = scoring_data.criterias |> List.first

      result = scoring_data |> HistogramCalculator.bin_vote_histogram(%{option: option6, criteria: criteria})
      assert [0, 0, 0, 0, 0] == result

      option6_histogram = scoring_data |> HistogramCalculator.bin_vote_histogram(%{option: option6})
      assert [2, 0, 0, 0, 1]  == option6_histogram

      option7_histogram = scoring_data |> HistogramCalculator.bin_vote_histogram(%{option: option7})
      assert [3, 0, 0, 0, 0]  == option7_histogram

      option8_histogram = scoring_data |> HistogramCalculator.bin_vote_histogram(%{option: option8})
      assert [2, 0, 0, 0, 1] == option8_histogram

      option9_histogram = scoring_data |> HistogramCalculator.bin_vote_histogram(%{option: option9})
      assert [3, 0, 0, 0, 0] == option9_histogram

      option10_histogram = scoring_data |> HistogramCalculator.bin_vote_histogram(%{option: option10})
      assert [2, 0, 0, 0, 1] == option10_histogram
    end

    test "histogram with rectangle slider votes support off" do

      # rectangle is oc 2 and options 6-10
      # should be identical with support on or off

      option_category_range_votes =  [
        %{high_option_id: 6, low_option_id: 6, option_category_id: 2, participant_id: 1},
        %{high_option_id: 8, low_option_id: 8, option_category_id: 2, participant_id: 2},
        %{high_option_id: 10, low_option_id: 10, option_category_id: 2, participant_id: 3},
      ]
      scoring_data = range_vote_data(option_category_range_votes, false)

      [option6, option7, option8, option9, option10 | _] = scoring_data.options_by_oc[2]
      criteria = scoring_data.criterias |> List.first

      result = scoring_data |> HistogramCalculator.bin_vote_histogram(%{option: option6, criteria: criteria})
      assert [0, 0, 0, 0, 0] == result

      option6_histogram = scoring_data |> HistogramCalculator.bin_vote_histogram(%{option: option6})
      assert [2, 0, 0, 0, 1]  == option6_histogram

      option7_histogram = scoring_data |> HistogramCalculator.bin_vote_histogram(%{option: option7})
      assert [3, 0, 0, 0, 0]  == option7_histogram

      option8_histogram = scoring_data |> HistogramCalculator.bin_vote_histogram(%{option: option8})
      assert [2, 0, 0, 0, 1] == option8_histogram

      option9_histogram = scoring_data |> HistogramCalculator.bin_vote_histogram(%{option: option9})
      assert [3, 0, 0, 0, 0] == option9_histogram

      option10_histogram = scoring_data |> HistogramCalculator.bin_vote_histogram(%{option: option10})
      assert [2, 0, 0, 0, 1] == option10_histogram
    end

    test "option category range votes counts" do

      option_category_range_votes =  [
        %{high_option_id: 3, low_option_id: 3, option_category_id: 1, participant_id: 1},
        %{high_option_id: 3, low_option_id: 3, option_category_id: 1, participant_id: 2},
        %{high_option_id: 1, low_option_id: 1, option_category_id: 1, participant_id: 3},
        %{high_option_id: 6, low_option_id: 6, option_category_id: 2, participant_id: 1},
        %{high_option_id: 10, low_option_id: 10, option_category_id: 2, participant_id: 2},
        %{high_option_id: 10, low_option_id: 10, option_category_id: 2, participant_id: 3},
      ]

      scoring_data = range_vote_data(option_category_range_votes, true)

      [option1, option2, option3 | _] = scoring_data.options_by_oc[1]
      [option6, option7, _, _, option10 | _] = scoring_data.options_by_oc[2]

      criteria = scoring_data.criterias |> List.first

      result_option_crit = scoring_data |> HistogramCalculator.option_range_vote_counts(%{option: option1, criteria: criteria})
      assert [1, 3] == result_option_crit

      option1_counts = scoring_data |> HistogramCalculator.option_range_vote_counts(%{option: option1})
      assert [1, 3] == option1_counts

      option2_counts = scoring_data |> HistogramCalculator.option_range_vote_counts(%{option: option2})
      assert [0, 3] == option2_counts

      option3_counts = scoring_data |> HistogramCalculator.option_range_vote_counts(%{option: option3})
      assert [2, 3] == option3_counts

      option1_counts = scoring_data |> HistogramCalculator.option_range_vote_counts(%{option: option6})
      assert [1, 3] == option1_counts

      option2_counts = scoring_data |> HistogramCalculator.option_range_vote_counts(%{option: option7})
      assert [0, 3] == option2_counts

      option3_counts = scoring_data |> HistogramCalculator.option_range_vote_counts(%{option: option10})
      assert [2, 3] == option3_counts

    end

end
