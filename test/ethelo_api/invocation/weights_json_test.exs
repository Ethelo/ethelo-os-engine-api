defmodule EtheloApi.Invocation.WeightsJsonTest do
  @moduledoc false
  use EtheloApi.DataCase
  @moduletag invocation: true

  import EtheloApi.Helpers.ExportHelper
  alias EtheloApi.Invocation.ScoringData
  alias EtheloApi.Invocation.WeightsJson

  def base_scoring_data() do
    %ScoringData{
      decision: %{id: 1},
      decision_id: 1,
      bin_votes: [],
      criterias: [],
      criteria_weights: [],
      options: [
        %{id: 1, option_category_id: 1, slug: "option1"},
        %{id: 2, option_category_id: 2, slug: "option2"}
      ],
      option_categories: [
        %{apply_participant_weights: true, id: 1, slug: "oc1", weighting: 50},
        %{apply_participant_weights: true, id: 2, slug: "oc2", weighting: 50}
      ],
      option_details: [],
      option_detail_values: [],
      option_category_weights: [],
      option_category_range_votes: [],
      participants: [],
      scenario_config: %{
        bins: 5,
        support_only: true
      }
    }
  end

  def add_indexes(scoring_data) do
    scoring_data
    |> Map.put(:option_categories_by_id, scoring_data.option_categories |> group_by_id())
    |> Map.put(:options_by_oc, scoring_data.options |> group_by_option_category())
    |> Map.put(:voting_participant_ids, scoring_data.participants |> Enum.map(& &1.id))
  end

  test "OptionCategory with no Options does not error" do
    scoring_data =
      base_scoring_data()
      |> Map.put(:criterias, [
        %{id: 1, slug: "one", weighting: 50}
      ])
      |> Map.put(:option_categories, [
        %{apply_participant_weights: false, id: 1, slug: "oc1", weighting: 1},
        %{apply_participant_weights: false, id: 3, slug: "oc3", weighting: 4}
      ])
      |> Map.put(:participants, [
        %{id: 1, weighting: Decimal.from_float(1.00)}
      ])
      |> add_indexes()

    result = scoring_data |> WeightsJson.build()

    expected = [[1.0, 0.0]]

    assert expected == result
  end

  test "weights on OptionCategory are normalized" do
    scoring_data =
      base_scoring_data()
      |> Map.put(:criterias, [
        %{id: 1, slug: "one", weighting: 50},
        %{id: 2, slug: "one", weighting: 50}
      ])
      |> Map.put(:option_categories, [
        %{apply_participant_weights: true, id: 1, slug: "oc1", weighting: 1},
        %{apply_participant_weights: true, id: 2, slug: "oc2", weighting: 2}
      ])
      |> Map.put(:participants, [
        %{id: 1, weighting: Decimal.from_float(1.00)}
      ])
      |> add_indexes()

    result = scoring_data |> WeightsJson.build()
    # 2 options x 2 criteria = 4 weights
    expected = [
      [0.16666666666666669, 0.16666666666666669, 0.33333333333333337, 0.33333333333333337]
    ]

    assert expected == result
  end

  test "Participant weights on OptionCategory are used when toggled on" do
    scoring_data =
      base_scoring_data()
      |> Map.put(:criterias, [
        %{id: 1, slug: "one", weighting: 50}
      ])
      |> Map.put(:option_categories, [
        %{apply_participant_weights: true, id: 1, slug: "oc1", weighting: 9},
        %{apply_participant_weights: false, id: 2, slug: "oc2", weighting: 9}
      ])
      |> Map.put(:participants, [
        %{id: 1, weighting: Decimal.from_float(1.00)},
        %{id: 2, weighting: Decimal.from_float(1.00)}
      ])
      |> Map.put(:option_category_weights, [
        %{option_category_id: 1, participant_id: 1, weighting: 3},
        %{option_category_id: 2, participant_id: 1, weighting: 3},
        %{option_category_id: 1, participant_id: 2, weighting: 6},
        %{option_category_id: 2, participant_id: 2, weighting: 6}
      ])
      |> add_indexes()

    result = WeightsJson.build(scoring_data)

    expected = [
      [0.05555555555555555, 0.16666666666666666],
      [0.1111111111111111, 0.16666666666666666]
    ]

    assert expected == result
  end

  test "weights on Criteria are normalized" do
    scoring_data =
      base_scoring_data()
      |> Map.put(:criterias, [
        %{id: 1, slug: "one", weighting: 100},
        %{id: 2, slug: "two", weighting: 300}
      ])
      |> Map.put(:participants, [
        %{id: 1, weighting: Decimal.from_float(1.00)}
      ])
      |> add_indexes()

    result = scoring_data |> WeightsJson.build()

    expected = [
      [0.125, 0.375, 0.125, 0.375]
    ]

    assert expected == result
  end

  test "Participant weights on Criteria are used when toggled on" do
    scoring_data =
      base_scoring_data()
      |> Map.put(:criterias, [
        %{id: 1, slug: "one", weighting: 10, apply_participant_weights: true},
        %{id: 2, slug: "two", weighting: 10, apply_participant_weights: false}
      ])
      |> Map.put(:options, [
        %{id: 1, option_category_id: 1, slug: "option1"}
      ])
      |> Map.put(:option_categories, [
        %{apply_participant_weights: true, id: 1, slug: "oc1", weighting: 9}
      ])
      |> Map.put(:participants, [
        %{id: 1, weighting: Decimal.from_float(1.00)},
        %{id: 2, weighting: Decimal.from_float(1.00)},
        %{id: 3, weighting: Decimal.from_float(1.00)}
      ])
      |> Map.put(:criteria_weights, [
        %{criteria_id: 1, participant_id: 1, weighting: 5},
        %{criteria_id: 1, participant_id: 2, weighting: 15}
      ])
      |> add_indexes()

    result = scoring_data |> WeightsJson.build()

    expected = [
      [0.02777777777777778, 0.05555555555555556],
      [0.08333333333333333, 0.05555555555555556],
      [0.05555555555555556, 0.05555555555555556]
    ]

    assert expected == result
  end

  test "weights on Participants are normalized" do
    scoring_data =
      base_scoring_data()
      |> Map.put(:criterias, [
        %{id: 1, slug: "one", weighting: 1, apply_participant_weights: true},
        %{id: 2, slug: "two", weighting: 1, apply_participant_weights: true}
      ])
      |> Map.put(:options, [
        %{id: 1, option_category_id: 1, slug: "option1"}
      ])
      |> Map.put(:option_categories, [
        %{apply_participant_weights: true, id: 1, slug: "oc1", weighting: 50}
      ])
      |> Map.put(:participants, [
        %{id: 1, weighting: Decimal.from_float(1.00)},
        %{id: 2, weighting: Decimal.from_float(4.00)}
      ])
      |> add_indexes()

    result = scoring_data |> WeightsJson.build()

    expected = [
      [0.03125, 0.03125],
      [0.125, 0.125]
    ]

    assert expected == result
  end
end
