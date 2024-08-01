defmodule EtheloApi.Structure.Docs.OptionDetail do
  @moduledoc "Central repository for documentation strings about OptionDetails."

  require DocsComposer

  @decision_id "Unique identifier for the Decision the OptionDetail belongs to. All OptionDetails are associated with a single Decision."

  @title "Name of OptionDetail. Used to generate slug if none supplied"

  @each_unique "OptionFilters and Filter Variables can be configured for each unique value."
  @format_string "Default Value. Data should be interpreted as text. #{@each_unique}"
  @format_integer "Data should be interpreted as an integer (no decimals). #{@each_unique}. Detail Variables can be configured for sums and means."
  @format_float "Data should be interpreted as a float/decimal. #{@each_unique}. Detail Variables can be configured for sums and means."
  @format_boolean "Data should be interpreted as a boolean (true/false). OptionFilters and Filter Variables can be configured for \"true\" and \"false\" matches"
  @format_datetime "Data should be interpreted a date with time. OptionFilter and Filter Variables can be configured for various time parts (Year, Month, ...)"
  @format_start """
  Each detail must have a format.

  Choosing a format DOES NOT add validation to the user's input. Format settings are used to identify what
  valid Variables and OptionFilters can be configured.
  Invalid values WILL NOT be included when calculations are run.
  """

  @format """
  #{@format_start}

  - string
    #{@format_string}
  - integer
    #{@format_integer}
  - float
    #{@format_float}
  - boolean
    #{@format_boolean}
  - datetime
    #{@format_datetime}

  """

  @option_detail """
  Configuration for arbitrary data added to an option.

  #{@format}
  """

  @display_hint """
  An optional string that can be used to trigger display code on the presentation layer.

  For example, a hint of "Dollars" or "Money" could be added to an OptionDetail to let the presentation layer know to format it as $x.xx
  It is up to the presentation layer to render or parse this field. The Ethelo engine does not use this value.
  """

  @input_hint """
  An optional string that can be used to provide guidance on how to fill out an OptionDetail on the presentation layer.

  For example, a hint of "YYYY-MM-DD" could be added to an OptionDetail to let the admin user setting up Options know the preferred format for dates.
  It is up to the presentation layer to render or parse this field. The Ethelo engine does not use this value.
  """

  @public """
  A boolean that indicates if the OptionDetail is appropriate to display to participants.

  It is up to the presentation layer to display or hide OptionDetails based on this field.
  """

  defp format_choices do
    DetailFormatEnum.__valid_values__()
    |> Enum.filter(fn(v) -> is_binary(v) end)
  end

  defp format_validation do
    format_choices()
    |> Enum.join(",")
    |> (&"Must be one of #{&1}").()
  end

  defp option_detail_fields() do
    [
     %{name: :title, info: @title, type: :string, validation: "Must include at least one word", required: true, automatic: false, immutable: false},
     %{name: :format, info: @format, type: :string, required: true, validation: format_validation()},
     %{name: :display_hint, info: @display_hint, type: :string, required: false},
     %{name: :input_hint, info: @input_hint, type: :string, required: false},
     %{name: :public, info: @public, type: :boolean, required: false},
     %{name: :decision_id, info: @decision_id, type: "id", required: true},
   ]
  end

  @doc """
  a list of maps describing all option_detail schema fields

  Suitable for use with `DocsComposer.schema_fields`.
  """
  def fields() do
    DocsComposer.common_fields([:id, :slug, :sort, :inserted_at, :updated_at]) ++ option_detail_fields()
  end

  @doc """
  Map describing example records

  Suitable for use with `DocsComposer.schema_examples`.
  """
  def examples() do
    %{
      "Boolean" => %{
        id: 1,
        public: true,
        format: "boolean",
        title: "Delivers?",
        slug: "delivers",
        display_hint: nil,
        input_hint: nil,
        decision_id: 1,
        sort: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
      },
      "Money" => %{
        id: 2,
        public: true,
        format: "float",
        display_hint: "$",
        input_hint: "Do not include dollar sign!",
        title: "Large Pizza Cost",
        slug: "large-pizza-cost",
        decision_id: 1,
        sort: 2,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
      },
      "Square Footage" => %{
        id: 4,
        public: true,
        format: "float",
        display_hint: "",
        input_hint: "",
        title: "Square Feet",
        slug: "sqft",
        decision_id: 1,
        sort: 3,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
      },
      "Percent" => %{
        id: 5,
        public: true,
        format: "number",
        display_hint: "%",
        input_hint: nil,
        title: "Frequent Buyer Discount",
        slug: "frequent-buyer-discount",
        decision_id: 1,
        sort: 4,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
      },
      "DateTime" => %{
        id: 6,
        public: true,
        format: "datetime",
        title: "Class Time",
        display_hint: "HH:MM PM",
        input_hint: "enter a date with time, the date won't be displayed",
        slug: "class-time",
        sort: 5,
        decision_id: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
      },
      "String" => %{
        id: 7,
        public: true,
        format: "string",
        title: "Crust Type",
        slug: "crust-type",
        decision_id: 1,
        sort: 6,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
      }
    }
  end

  @doc """
  strings describing each field as well as the general concept of "option_details"
  """
  def strings() do
    option_detail_strings = %{
      option_detail: @option_detail,
      display_hint: @display_hint,
      input_hint: @input_hint,
      public: @public,
      format: @format,
      title: @title,
      decision_id: @decision_id,
      format_string: @format_string,
      format_boolean: @format_boolean,
      format_integer: @format_integer,
      format_float: @format_float,
      format_datetime: @format_datetime,
      format_start: @format_start
    }
    DocsComposer.common_strings() |> Map.merge(option_detail_strings)
  end

end
