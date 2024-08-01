defmodule EtheloApi.Structure.Docs.OptionFilter do
  @moduledoc "Central repository for documentation strings about OptionFilters."

  require DocsComposer

  @option_filter "OptionFilters can be used to select a group of Options according to their OptionDetailValues or their OptionCategory.
    These groups of Options can be used to apply constraints to a subset of Options.
    They can also be used by the presentation layer to display related options together.

    The decision will always have an \"All Options\" Filter defined. This OptionFilter cannot be deleted,
    and will be used as the default OptionFilter for Calculations and Constraints. The match_mode for this special OptionFilter will be \"all_options\".

    The system can suggest common OptionFilters that could be used to match OptionDetailValues or OptionCategories.
    These can be used to quickly create OptionFilters.
    "
  @decision_id "Unique identifier for the Decision the OptionFilter belongs to. All OptionFilters are associated with a single Decision."

  @title "Name of OptionFilter. Used to generate slug if none supplied"

  @match_mode "Type of match to support."

  @match_mode_tutorial """
   For OptionCategories, in category (`in_category`) and not in category (`not_in_category`) is supported.

   For most OptionDetails, only an exact match (`equals`) is supported.

  """

  @match_mode_validation "For matching an Option Category, must be `in_category` or `not_in_category`.

   For boolean, number or string OptionDetails, must be `equals`.

  "

  @match_mode_all_options "Matches all Options."
  @match_mode_in_category "Matches all Options in the associated Option Category."
  @match_mode_not_in_category "Matches all Options not in the associated Option Category."
  @match_mode_equals "Matches all Options with an OptionDetailValue matching the supplied matchValue and OptionDetail."

  @match_value "The value to match against. If an invalid or nonexistant value is used, the OptionFilter will match no Options. Empty strings are allowed. Will be empty when matching all Options or matching an OptionCategory."

  @option_detail "Configuration for arbitrary data added to an Option."

  @option_detail_id "The OptionDetail to source the value from. All OptionFilter must define an OptionDetail."

  @option_category_id "The OptionCategory to match."

  @option_category "OptionCategories are used to specify the importance of Options. Each group has a specific \"weight\" applied, making the Options more or less important when calculating the best result."

  @options "A list of Options matched by the OptionFilter"

  @option_ids "A list of Option ids matched by the OptionFilter"

  @enabled_only "A toggle specifying if filter matches should be restricted to Options with an `enabled` value of `true`"

  @weighting "Multiplier for a Decision-wide weighting to all votes to options matching this OptionFilter. Participant specific weightings can also be entered."

  defp option_filter_fields() do
    [
     %{name: :title, match_value: @title, type: :string, validation: "Must include at least one word", required: true, automatic: false, immutable: false},
     %{name: :match_mode, match_value: @match_mode, type: :string, required: false, validation: @match_mode_validation},
     %{name: :match_value, match_value: @match_value, type: :string, required: false},
     %{name: :weighting, info: @weighting, type: :integer, validation: "must be between 1 and 100", required: false, automatic: false, immutable: false},
     %{name: :option_detail_id, match_value: @option_detail_id, type: "id", required: true, validation: "must be part of the same decision. Must be nil if option_category_id is specified."},
     %{name: :option_category_id, match_value: @option_category_id, type: "id", required: true, validation: "must be part of the same decision. Must be nil if option_detail_id is specified."},
     %{name: :decision_id, match_value: @decision_id, type: "id", required: true},
   ]
  end

  @doc """
  a list of maps describing all option_filter schema fields

  Suitable for use with `DocsComposer.schema_fields`.
  """
  def fields() do
    DocsComposer.common_fields([:id, :slug, :inserted_at, :updated_at]) ++ option_filter_fields()
  end

  @doc """
  Map describing example records

  Suitable for use with `DocsComposer.schema_examples`.
  """
  def examples() do
    %{
      "Sample 1" => %{
        id: 1,
        match_mode: "equals",
        title: "Options with Delivery",
        slug: "with_delivery",
        match_value: "1",
        weighting: nil,
        option_detail_id: 1,
        option_category_id: nil,
        decision_id: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
      },
      "Sample 2" => %{
        id: 2,
        match_mode: "equals",
        title: "Options without sides",
        slug: "without_sides",
        match_value: "",
        option_category_id: 1,
        option_detail_id: nil,
        weighting: nil,
        decision_id: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
      },
      "Sample 3" => %{
        id: 1,
        match_mode: "equals",
        title: "Delivery Options",
        slug: "places_that_deliver",
        match_value: "1",
        weighting: nil,
        option_detail_id: 1,
        option_category_id: nil,
        decision_id: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-07T22:48:16+00:00",
      },
    }
  end

  @doc """
  strings describing each field as well as the general concept of "option_filters"
  """
  def strings() do
    option_filter_strings = %{
      option_filter: @option_filter,
      match_value: @match_value,
      match_mode: @match_mode <> @match_mode_tutorial,
      title: @title,
      weighting: @weighting,
      option_detail: @option_detail,
      option_detail_id: @option_detail_id,
      option_category: @option_category,
      option_category_id: @option_category_id,
      decision_id: @decision_id,
      option_ids: @option_ids,
      options: @options,
      enabled_only: @enabled_only,
      match_mode_all_options: @match_mode_all_options,
      match_mode_in_category: @match_mode_in_category,
      match_mode_not_in_category: @match_mode_not_in_category,
      match_mode_equals: @match_mode_equals,
    }
    DocsComposer.common_strings() |> Map.merge(option_filter_strings)
  end

end
