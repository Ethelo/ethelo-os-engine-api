defmodule EtheloApi.Invocation.InfluentsJsonTest do
  @moduledoc false
  use EtheloApi.DataCase
  @moduletag invocation: true

  import EtheloApi.Helpers.ExportHelper
  alias EtheloApi.Invocation.ScoringData
  alias EtheloApi.Invocation.InfluentsJson

  def base_scoring_data() do
    %ScoringData{
      decision: %{id: 1},
      decision_id: 1,
      bin_votes: [],
      criterias: [
        %{id: 1, slug: "one", weighting: 50}
      ],
      options: [
        %{id: 1, option_category_id: 1, slug: "option1"}
      ],
      option_categories: [
        %{id: 1, slug: "oc1", weighting: 50, primary_detail_id: 1, scoring_mode: :rectangle}
      ],
      option_details: [
        %{decision_id: 1, format: :float, id: 1, slug: "float", title: "Float"},
        %{decision_id: 2, format: :float, id: 2, slug: "float2", title: "Float2"}
      ],
      option_detail_values: [],
      option_category_range_votes: [],
      participants: []
    }
  end

  def add_indexes(scoring_data) do
    scoring_data
    |> Map.put(:option_categories_by_id, scoring_data.option_categories |> group_by_id())
    |> Map.put(:option_details_by_id, scoring_data.option_details |> group_by_id())
    |> Map.put(:options_by_id, scoring_data.options |> group_by_id())
    |> Map.put(:options_by_oc, scoring_data.options |> group_by_option_category())
    |> Map.put(:voting_participant_ids, scoring_data.participants |> Enum.map(& &1.id))
  end

  test "single vote without support only" do
    scoring_data =
      base_scoring_data()
      |> Map.put(
        :scenario_config,
        %{support_only: true, bins: 5}
      )
      |> Map.put(:bin_votes, [
        %{option_id: 1, criteria_id: 1, participant_id: 1, bin: 5}
      ])
      |> Map.put(:participants, [
        %{id: 1, weighting: Decimal.from_float(1.00)}
      ])
      |> add_indexes()

    result = scoring_data |> InfluentsJson.build()

    expected = [
      [1.0]
    ]

    assert expected == result
  end

  test "single bin voting" do
    scoring_data =
      base_scoring_data()
      |> Map.put(
        :scenario_config,
        %{support_only: true, bins: 1}
      )
      |> Map.put(:bin_votes, [
        %{option_id: 1, criteria_id: 1, participant_id: 1, bin: 1}
      ])
      |> Map.put(:participants, [
        %{id: 1, weighting: Decimal.from_float(1.00)}
      ])
      |> add_indexes()

    result = scoring_data |> InfluentsJson.build()

    expected = [
      [1.0]
    ]

    assert expected == result
  end

  test "multiple votes with support only" do
    scoring_data =
      base_scoring_data()
      |> Map.put(
        :scenario_config,
        %{support_only: true, bins: 5}
      )
      |> Map.put(:participants, [
        %{id: 1, weighting: Decimal.from_float(1.00)},
        %{id: 2, weighting: Decimal.from_float(1.00)},
        %{id: 3, weighting: Decimal.from_float(1.00)},
        %{id: 4, weighting: Decimal.from_float(1.00)},
        %{id: 5, weighting: Decimal.from_float(1.00)}
      ])
      |> Map.put(:bin_votes, [
        %{option_id: 1, criteria_id: 1, participant_id: 1, bin: 1},
        %{option_id: 1, criteria_id: 1, participant_id: 2, bin: 2},
        %{option_id: 1, criteria_id: 1, participant_id: 3, bin: 3},
        %{option_id: 1, criteria_id: 1, participant_id: 4, bin: 4},
        %{option_id: 1, criteria_id: 1, participant_id: 5, bin: 5}
      ])
      |> add_indexes()

    result = scoring_data |> InfluentsJson.build()
    expected = [[0.0], [0.25], [0.5], [0.75], [1.0]]

    assert expected == result
  end

  test "multiple votes without support only" do
    scoring_data =
      base_scoring_data()
      |> Map.put(
        :scenario_config,
        %{support_only: false, bins: 5}
      )
      |> Map.put(:participants, [
        %{id: 1, weighting: Decimal.from_float(1.00)},
        %{id: 2, weighting: Decimal.from_float(1.00)},
        %{id: 3, weighting: Decimal.from_float(1.00)},
        %{id: 4, weighting: Decimal.from_float(1.00)},
        %{id: 5, weighting: Decimal.from_float(1.00)}
      ])
      |> Map.put(:bin_votes, [
        %{option_id: 1, criteria_id: 1, participant_id: 1, bin: 1},
        %{option_id: 1, criteria_id: 1, participant_id: 2, bin: 2},
        %{option_id: 1, criteria_id: 1, participant_id: 3, bin: 3},
        %{option_id: 1, criteria_id: 1, participant_id: 4, bin: 4},
        %{option_id: 1, criteria_id: 1, participant_id: 5, bin: 5}
      ])
      |> add_indexes()

    result = scoring_data |> InfluentsJson.build()
    expected = [[-1.0], [-0.5], [0.0], [0.5], [1.0]]

    assert expected == result
  end

  test "null votes show as null" do
    scoring_data =
      base_scoring_data()
      |> Map.put(
        :scenario_config,
        %{support_only: true, bins: 5}
      )
      |> Map.put(:options, [
        %{id: 1, option_category_id: 1, slug: "option1"},
        # should show first always
        %{id: 2, option_category_id: 1, slug: "aaa"}
      ])
      |> Map.put(:participants, [
        %{id: 1, weighting: Decimal.from_float(1.00)},
        %{id: 2, weighting: Decimal.from_float(1.00)}
      ])
      |> Map.put(:bin_votes, [
        %{option_id: 1, criteria_id: 1, participant_id: 1, bin: 1},
        %{option_id: 2, criteria_id: 1, participant_id: 2, bin: 1}
      ])
      |> add_indexes()

    result = scoring_data |> InfluentsJson.build()
    expected = [[nil, 0.0], [0.0, nil]]

    assert expected == result
  end

  test "rectangle votes score correctly" do
    scoring_data =
      base_scoring_data()
      |> Map.put(
        :scenario_config,
        %{support_only: true, bins: 5}
      )
      |> Map.put(:option_categories, [
        %{id: 1, slug: "oc1", scoring_mode: :rectangle, primary_detail_id: 1},
        %{id: 2, slug: "oc2", scoring_mode: :none, primary_detail_id: nil}
      ])
      |> Map.put(:options, [
        %{id: 1, option_category_id: 1, slug: "option1"},
        %{id: 2, option_category_id: 1, slug: "option2"},
        %{id: 3, option_category_id: 2, slug: "option3"}
      ])
      |> Map.put(:option_detail_values, [
        %{option_detail_id: 1, option_id: 1, value: 1},
        %{option_detail_id: 1, option_id: 2, value: 3},
        %{option_detail_id: 2, option_id: 3, value: 7}
      ])
      |> Map.put(:option_category_range_votes, [
        %{high_option_id: 1, low_option_id: 1, option_category_id: 1, participant_id: 1},
        %{high_option_id: 3, low_option_id: 3, option_category_id: 2, participant_id: 1}
      ])
      |> Map.put(:participants, [
        %{id: 1, weighting: Decimal.from_float(1.00)}
      ])
      |> add_indexes()

    result = scoring_data |> InfluentsJson.build()
    expected = [[1.0, 0.0, nil]]

    assert expected == result
  end

  test "triangle votes score correctly when centered" do
    scoring_data =
      base_scoring_data()
      |> Map.put(
        :scenario_config,
        %{support_only: true, bins: 5}
      )
      |> Map.put(:option_categories, [
        %{id: 1, slug: "oc1", scoring_mode: :triangle, triangle_base: 3, primary_detail_id: 1}
      ])
      |> Map.put(:options, [
        %{id: 1, option_category_id: 1, slug: "option1"},
        %{id: 2, option_category_id: 1, slug: "option2"},
        %{id: 3, option_category_id: 1, slug: "option3"},
        %{id: 4, option_category_id: 1, slug: "option4"},
        %{id: 5, option_category_id: 1, slug: "option5"}
      ])
      |> Map.put(:option_detail_values, [
        %{option_detail_id: 1, option_id: 1, value: 1},
        %{option_detail_id: 1, option_id: 2, value: 2},
        %{option_detail_id: 1, option_id: 3, value: 3},
        %{option_detail_id: 1, option_id: 4, value: 4},
        %{option_detail_id: 1, option_id: 5, value: 5}
      ])
      |> Map.put(:option_category_range_votes, [
        %{high_option_id: 3, low_option_id: 3, option_category_id: 1, participant_id: 1}
      ])
      |> Map.put(:participants, [
        %{id: 1, weighting: Decimal.from_float(1.00)}
      ])
      |> add_indexes()

    result = scoring_data |> InfluentsJson.build()
    expected = [[0.0, 0.5, 1.0, 0.5, 0.0]]

    assert expected == result
  end

  test "triangle votes score correctly without support" do
    scoring_data =
      base_scoring_data()
      |> Map.put(
        :scenario_config,
        %{support_only: false, bins: 5}
      )
      |> Map.put(:option_categories, [
        %{id: 1, slug: "oc1", scoring_mode: :triangle, triangle_base: 5, primary_detail_id: 1}
      ])
      |> Map.put(:options, [
        %{id: 1, option_category_id: 1, slug: "option1"},
        %{id: 2, option_category_id: 1, slug: "option2"},
        %{id: 3, option_category_id: 1, slug: "option3"},
        %{id: 4, option_category_id: 1, slug: "option4"},
        %{id: 5, option_category_id: 1, slug: "option5"},
        %{id: 6, option_category_id: 1, slug: "option6"},
        %{id: 7, option_category_id: 1, slug: "option7"}
      ])
      |> Map.put(:option_detail_values, [
        %{option_detail_id: 1, option_id: 1, value: 1},
        %{option_detail_id: 1, option_id: 2, value: 2},
        %{option_detail_id: 1, option_id: 3, value: 3},
        %{option_detail_id: 1, option_id: 4, value: 4},
        %{option_detail_id: 1, option_id: 5, value: 5},
        %{option_detail_id: 1, option_id: 6, value: 6},
        %{option_detail_id: 1, option_id: 7, value: 7}
      ])
      |> Map.put(:option_category_range_votes, [
        %{high_option_id: 4, low_option_id: 4, option_category_id: 1, participant_id: 1}
      ])
      |> Map.put(:participants, [
        %{id: 1, weighting: Decimal.from_float(1.00)}
      ])
      |> add_indexes()

    result = scoring_data |> InfluentsJson.build()

    expected = [
      [
        -1.0,
        -0.33333333333333326,
        0.3333333333333335,
        1.0,
        0.3333333333333335,
        -0.33333333333333326,
        -1.0
      ]
    ]

    assert expected == result
  end

  test "triangle votes score correctly with base 1" do
    scoring_data =
      base_scoring_data()
      |> Map.put(
        :scenario_config,
        %{support_only: true, bins: 5}
      )
      |> Map.put(:option_categories, [
        %{id: 1, slug: "oc1", scoring_mode: :triangle, triangle_base: 1, primary_detail_id: 1}
      ])
      |> Map.put(:options, [
        %{id: 1, option_category_id: 1, slug: "option1"},
        %{id: 2, option_category_id: 1, slug: "option2"},
        %{id: 3, option_category_id: 1, slug: "option3"},
        %{id: 4, option_category_id: 1, slug: "option4"},
        %{id: 5, option_category_id: 1, slug: "option5"}
      ])
      |> Map.put(:option_detail_values, [
        %{option_detail_id: 1, option_id: 1, value: 1},
        %{option_detail_id: 1, option_id: 2, value: 2},
        %{option_detail_id: 1, option_id: 3, value: 3},
        %{option_detail_id: 1, option_id: 4, value: 4},
        %{option_detail_id: 1, option_id: 5, value: 5}
      ])
      |> Map.put(:option_category_range_votes, [
        %{high_option_id: 3, low_option_id: 3, option_category_id: 1, participant_id: 1}
      ])
      |> Map.put(:participants, [
        %{id: 1, weighting: Decimal.from_float(1.00)}
      ])
      |> add_indexes()

    result = scoring_data |> InfluentsJson.build()
    expected = [[0, 0, 1, 0, 0]]

    assert expected == result
  end

  test "triangle votes score correctly with offset vote" do
    scoring_data =
      base_scoring_data()
      |> Map.put(
        :scenario_config,
        %{support_only: true, bins: 5}
      )
      |> Map.put(:option_categories, [
        %{id: 1, slug: "oc1", scoring_mode: :triangle, triangle_base: 5, primary_detail_id: 1}
      ])
      |> Map.put(:options, [
        %{id: 1, option_category_id: 1, slug: "option1"},
        %{id: 2, option_category_id: 1, slug: "option2"},
        %{id: 3, option_category_id: 1, slug: "option3"},
        %{id: 4, option_category_id: 1, slug: "option4"},
        %{id: 5, option_category_id: 1, slug: "option5"}
      ])
      |> Map.put(:option_detail_values, [
        %{option_detail_id: 1, option_id: 1, value: 1},
        %{option_detail_id: 1, option_id: 2, value: 2},
        %{option_detail_id: 1, option_id: 3, value: 3},
        %{option_detail_id: 1, option_id: 4, value: 4},
        %{option_detail_id: 1, option_id: 5, value: 5}
      ])
      |> Map.put(:option_category_range_votes, [
        %{high_option_id: 2, low_option_id: 2, option_category_id: 1, participant_id: 1}
      ])
      |> Map.put(:participants, [
        %{id: 1, weighting: Decimal.from_float(1.00)}
      ])
      |> add_indexes()

    result = scoring_data |> InfluentsJson.build()
    expected = [[0.6666666666666667, 1.0, 0.6666666666666667, 0.33333333333333337, 0.0]]

    assert expected == result
  end

  test "triangle votes score correctly when triangle size > Option count" do
    scoring_data =
      base_scoring_data()
      |> Map.put(
        :scenario_config,
        %{support_only: true, bins: 5}
      )
      |> Map.put(:option_categories, [
        %{id: 1, slug: "oc1", scoring_mode: :triangle, triangle_base: 6, primary_detail_id: 1}
      ])
      |> Map.put(:options, [
        %{id: 1, option_category_id: 1, slug: "option1"},
        %{id: 2, option_category_id: 1, slug: "option2"},
        %{id: 3, option_category_id: 1, slug: "option3"},
        %{id: 4, option_category_id: 1, slug: "option4"}
      ])
      |> Map.put(:option_detail_values, [
        %{option_detail_id: 1, option_id: 1, value: 1},
        %{option_detail_id: 1, option_id: 2, value: 2},
        %{option_detail_id: 1, option_id: 3, value: 3},
        %{option_detail_id: 1, option_id: 4, value: 4}
      ])
      |> Map.put(:option_category_range_votes, [
        %{high_option_id: 2, low_option_id: 2, option_category_id: 1, participant_id: 1}
      ])
      |> Map.put(:participants, [
        %{id: 1, weighting: Decimal.from_float(1.00)}
      ])
      |> add_indexes()

    result = scoring_data |> InfluentsJson.build()
    expected = [[0.6666666666666667, 1.0, 0.6666666666666667, 0.33333333333333337]]

    assert expected == result
  end

  test "mix of triangle and normal categories" do
    scoring_data =
      base_scoring_data()
      |> Map.put(
        :scenario_config,
        %{support_only: true, bins: 5}
      )
      |> Map.put(:option_categories, [
        %{id: 1, slug: "oc1", scoring_mode: :triangle, triangle_base: 3, primary_detail_id: 1},
        %{id: 2, slug: "oc1", scoring_mode: :none}
      ])
      |> Map.put(:options, [
        %{id: 1, option_category_id: 1, slug: "option1"},
        %{id: 2, option_category_id: 1, slug: "option2"},
        %{id: 3, option_category_id: 1, slug: "option3"},
        %{id: 4, option_category_id: 2, slug: "option4"}
      ])
      |> Map.put(:option_detail_values, [
        %{option_detail_id: 1, option_id: 1, value: 1},
        %{option_detail_id: 1, option_id: 2, value: 2},
        %{option_detail_id: 1, option_id: 3, value: 3},
        %{option_detail_id: 1, option_id: 4, value: 4}
      ])
      |> Map.put(:option_category_range_votes, [
        %{high_option_id: 2, low_option_id: 2, option_category_id: 1, participant_id: 1}
      ])
      |> Map.put(:participants, [
        %{id: 1, weighting: Decimal.from_float(1.00)}
      ])
      |> add_indexes()

    result = scoring_data |> InfluentsJson.build()
    expected = [[0.5, 1.0, 0.5, nil]]

    assert expected == result
  end

  test "triangle votes without primary detail id are null" do
    scoring_data =
      base_scoring_data()
      |> Map.put(
        :scenario_config,
        %{support_only: true, bins: 5}
      )
      |> Map.put(:option_categories, [
        %{id: 1, slug: "oc1", scoring_mode: :triangle, triangle_base: 3, primary_detail_id: nil},
        %{id: 2, slug: "oc1", scoring_mode: :none}
      ])
      |> Map.put(:options, [
        %{id: 1, option_category_id: 1, slug: "option1"},
        %{id: 2, option_category_id: 1, slug: "option2"},
        %{id: 3, option_category_id: 1, slug: "option3"},
        %{id: 4, option_category_id: 2, slug: "option4"}
      ])
      |> Map.put(:option_detail_values, [
        %{option_detail_id: 1, option_id: 1, value: 1},
        %{option_detail_id: 1, option_id: 2, value: 2},
        %{option_detail_id: 1, option_id: 3, value: 3},
        %{option_detail_id: 1, option_id: 4, value: 4}
      ])
      |> Map.put(:option_category_range_votes, [
        %{high_option_id: 2, low_option_id: 2, option_category_id: 1, participant_id: 1}
      ])
      |> Map.put(:participants, [
        %{id: 1, weighting: Decimal.from_float(1.00)}
      ])
      |> add_indexes()

    result = scoring_data |> InfluentsJson.build()
    expected = [[nil, nil, nil, nil]]

    assert expected == result
  end
end
