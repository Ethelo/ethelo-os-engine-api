defmodule EtheloApi.Structure.Docs.OptionCategory do
  @moduledoc "Central repository for documentation strings about OptionCategories."

  require DocsComposer

  @decision_id "Unique identifier for the Decision the OptionCategory belongs to. All OptionCategories are associated with a single Decision."

  @option_category """
  OptionCategories are used to specify the importance of Options. Each group has a specific "weight" applied, making the Options more or less important when calculating the best result.

  Weighting is applied on a scale of 1 to 100. By default, OptionCategories have a weight of 100.

  All decisions have a single OptionCategory by default: "uncategorized". All Options must belong to an OptionCategory, and new Options will be placed in the default category.

  Participants can also weight the importance of various OptionCategories though OptionCategoryWeights.

  In these cases, their scores will be weighted based on their preference before being used to select a Decision.
  """

  @option_category_example """
  A simple example when choosing what to order for team lunch.

  The Decision is set up with Options organized into "Food" and "Drink" OptionCategories.
  There are some drinks available in the office, so it's less important to get
  drinks that everyone likes.

  In this case, the Drink Category would be given a low weighting - 10, while the Food
  Category would be given a high weighting - 90.

  When Ethelo calculates the available scenarios, it will prioritize combinations with
  a high approval rating on the "Food" options over those with a low approval rating on "Food" options.
  """

  @title "Name of OptionCategory. Used to generate slug if none supplied"
  @info "Informative text describing the OptionCategory."
  @keywords "Text used by frontend search feature"
  @results_title "Optional alternate title to use in charts"

  @weighting "Multiplier for a Decision-wide weighting to all votes to Options in the OptionCategory. Participant specific weightings can also be entered through OptionCategoryWeights."

  @options "Options are the choices that a make up a Decision solution. Your solution may include multiple Options."

  @option_ids "A list of option ids in the specified OptionCategory"

  @xor "A boolean indicating if this optionCategory should have an XOR constraint applied (only one Option in the OptionCategory can be chosen in the solution. This constraint will not show when querying other constraints. )"
  @primary_detail_id "The OptionDetail to use to order the options when converting OptionCategoryBinVotes or OptionCategoryRangeVotes to BinVotes."
  @primary_detail "The OptionDetail to use to order the options when converting OptionCategoryBinVotes or OptionCategoryRangeVotes to BinVotes."
  @option_detail "Configuration for arbitrary data added to an Option."

  @default_high_option_id "The default 'high' option to use when range votes are applied. This value only affects the frontend and is not used when calculating scenarios."
  @default_low_option_id "The default option to use when 'pick one' votes are applied, or the 'low' option to use when range votes are applied. This value only affects the frontend and is not used when calculating scenarios."

  @apply_participant_weights "A boolean indicating if participant weighting should be applied to this OptionCategory"
  @budget_percent "The % amount of the total budget this category represents. Used to calculate tax assessment values."
  @flat_fee "The $ amount this category adds to every tax assessment. Used to calculate tax assessment values."
  @vote_on_percent "Toggle if votes are on the percentage value or the flat fee value"
  @quadratic "If Quadradtic Voting should be used"
  @voting_range "Display a voting widget that allows input of both a 'high' and a 'low' option. Votes will be applied to all items in the range. "
  @voting_one "Display a voting widget that allows input of a single option."
  @voting_start """
  This value is used to indicate which voting widget to use for this OptionCategory on the frontend. This is only applied when using triangle or rectangle voting modes. This value only affects the frontend and is not used when calculating scenarios.
  """

  @voting_style """
  #{@voting_start}

  - range
    #{@voting_range}
  - one
    #{@voting_one}

  """

  @scoring_none "Default Value. Option Category Voting will not be applied."
  @scoring_rectangle "Selected items are assigned BinVotes at Bin 9 (highest possible), remaining Options have BinVotes at the bin 1"
  @scoring_triangle "Highest BinVote is at selected item, and reduces for items farther away. The farthest ends have BinVotes in bin 1"
  @scoring_start """
  When OptionCategoryBinVotes or OptionCategoryRangeVotes exist, the scoring mode is used to convert them into BinVotes.

  To convert to bin votes, the options in the category are sorted by the primary_detail_id to put them in an ordered list. This list is then used to determine if an option is selected or not.
  """

  @scoring_mode """
  #{@scoring_start}

  - none
    #{@scoring_none}
  - rectangle
    #{@scoring_rectangle}
  - triangle
    #{@scoring_triangle}

  """

  defp scoring_mode_choices do
    ScoringModeEnum.__valid_values__()
    |> Enum.filter(fn(v) -> is_binary(v) end)
  end

  defp scoring_mode_validation do
    scoring_mode_choices()
    |> Enum.join(",")
    |> (&"Must be one of #{&1}").()
  end

  defp voting_style_choices do
    VotingStyleEnum.__valid_values__()
    |> Enum.filter(fn(v) -> is_binary(v) end)
  end

  defp voting_style_validation do
    voting_style_choices()
    |> Enum.join(",")
    |> (&"Must be one of #{&1}").()
  end


  @triangle_base """
  The width of the triangle (number of Options included) to use in triangle scoring
  """


  defp option_categories_fields() do
    [
     %{name: :title, info: @title, type: :string, validation: "Must include at least one word", required: true, automatic: false, immutable: false},
     %{name: :results_title, info: @results_title, type: :string, validation: "Must include at least one word", required: false, automatic: false, immutable: false},
     %{name: :info, info: @info, type: "html", required: false, automatic: false, immutable: false},
     %{name: :keywords, info: @keywords, type: "text", required: false, automatic: false, immutable: false},
     %{name: :weighting, info: @weighting, type: :integer,  validation: "must be between 1 and 100", required: true, automatic: false, immutable: false},
     %{name: :vote_on_percent, info: @vote_on_percent, type: :boolean , required: true, default: true},
     %{name: :quadratic, info: @quadratic, type: :boolean , required: true, default: false},
     %{name: :budget_percent, info: @budget_percent, type: :float,  validation: "numeric", required: false, automatic: false, immutable: false},
     %{name: :flat_fee, info: @flat_fee, type: :float,  validation: "numeric", required: false, automatic: false, immutable: false},
     %{name: :scoring_mode, info: @scoring_mode, type: :string, required: true, validation: scoring_mode_validation()},
     %{name: :triangle_base, info: @triangle_base, type: :integer , required: false, default: 3},
     %{name: :xor, info: @xor, type: :boolean , required: true, default: false},
     %{name: :apply_participant_weights, info: @apply_participant_weights, type: :boolean , required: true, default: true},
     %{name: :primary_detail_id, info: @primary_detail_id, type: "id" , required: true, validation: "must be part of the same Decision as the OptionCategory"},
     %{name: :voting_style, info: @voting_style, type: :string, required: true, validation: voting_style_validation()},
     %{name: :default_high_option_id, info: @default_high_option_id, type: "id" , required: true, validation: "must be part of the same Decision as the OptionCategory"},
     %{name: :default_low_option_id, info: @default_low_option_id, type: "id" , required: true, validation: "must be part of the same Decision as the OptionCategory"},
     %{name: :decision_id, info: @decision_id, type: "id" , required: true},
   ]
  end

  @doc """
  a list of maps describing all option_categories schema fields

  Suitable for use with `DocsComposer.schema_fields`.
  """
  def fields() do
    DocsComposer.common_fields([:id, :slug, :sort, :deleted, :inserted_at, :updated_at]) ++ option_categories_fields()
  end

  @doc """
  Map describing example records

  Suitable for use with `DocsComposer.schema_examples`.
  """
  def examples() do
    %{
      "Default" => %{
        id: 1,
        title: "Uncategorized Options",
        slug: "uncategorized",
        info: "Options not in a category",
        decision_id: 1,
        weighting: nil,
        deleted: false,
        xor: false,
        vote_on_percent: true,
        quadratic: true,
        results_title: "Alt Title",
        flat_fee: nil,
        keywords: nil,
        budget_percent: nil,
        apply_participant_weights: true,
        primary_detail_id: nil,
        scoring_mode: "none",
        triangle_base: nil,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
        voting_style: "one",
        default_high_option_id: nil,
        default_low_option_id: nil,
      },
      "Food" => %{
        id: 2,
        title: "Food",
        slug: "food",
        info: "How important are the Food Options?",
        keywords: "food, eating",
        weighting: 9,
        decision_id: 1,
        deleted: false,
        xor: false,
        vote_on_percent: true,
        quadratic: true,
        results_title: "yum",
        apply_participant_weights: true,
        budget_percent: 10,
        flat_fee: 1,
        primary_detail_id: nil,
        scoring_mode: "none",
        triangle_base: nil,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
        voting_style: "one",
        default_high_option_id: nil,
        default_low_option_id: nil,
      },
      "Drink" => %{
        id: 3,
        title: "Drink",
        slug: "Drink",
        info: "How important are the Drink Options?",
        keywords: nil,
        decision_id: 1,
        weighting: 1,
        deleted: false,
        xor: true,
        vote_on_percent: false,
        quadratic: false,
        results_title: nil,
        apply_participant_weights: false,
        budget_percent: 10.2,
        flat_fee: 2.3,
        primary_detail_id: 2,
        scoring_mode: "rectangle",
        triangle_base: nil,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
        voting_style: "one",
        default_high_option_id: nil,
        default_low_option_id: nil,
      }
    }
  end

  @doc """
  strings describing each field as well as the general concept of "option_categories"
  """
  def strings() do
    strings = %{
      option_category: @option_category,
      info: @info,
      keywords: @keywords,
      option_ids: @option_ids,
      options: @options,
      option_detail: @option_detail,
      weighting: @weighting,
      title: @title,
      mini_tutorial: @option_category_example,
      decision_id: @decision_id,
      xor: @xor,
      budget_percent: @budget_percent,
      flat_fee: @flat_fee,
      apply_participant_weights: @apply_participant_weights,
      primary_detail_id: @primary_detail_id,
      primary_detail: @primary_detail,
      scoring_mode: @scoring_mode,
      triangle_base: @triangle_base,
      scoring_none: @scoring_none,
      scoring_rectangle: @scoring_rectangle,
      scoring_triangle: @scoring_triangle,
      scoring_start: @scoring_start,
      default_high_option_id: @default_high_option_id,
      default_low_option_id: @default_low_option_id,
      vote_on_percent: @vote_on_percent,
      quadratic: @quadratic,
      results_title: @results_title,
      voting_style: @voting_style,
      voting_one: @voting_one,
      voting_range: @voting_range,
      voting_start: @voting_start,

    }
    DocsComposer.common_strings() |> Map.merge(strings)
  end

end
