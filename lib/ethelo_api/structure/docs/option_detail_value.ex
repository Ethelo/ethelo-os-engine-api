defmodule EtheloApi.Structure.Docs.OptionDetailValue do
  @moduledoc "Central repository for documentation strings about OptionDetailValues."

  require DocsComposer

  @decision_id "The Decision the OptionDetailValue belongs to."

  @option_id "The Option the OptionDetailValue belongs to. Options are the choices that a make up a Decision solution. "

  @option_detail_id "The OptionDetail the OptionDetailValue belongs to. Option Details allow arbitrary data to be added to an Option."

  @value "string value of OptionDetail for specified Option"

  @option_detail_value """
  Option details allow configuration of arbitrary data to be added to each Option.

  After an OptionDetail is defined, you can insert specific OptionDetailValues for each Option you create.
  Specifying values has several uses:

  - OptionDetailValues are easily listed for display or comparison
  - some OptionDetailValues (like numbers) allow you to add Variables to your Decision. Variables allow you to perform math on your Decision - for example to calculate total cost.
  """

  @mini_tutorial """
  Here's an example:

  Set up an OptionDetail for Cost, with the following values

  - id: 1
  - format: number
  - title: cost

  Then, when you create or update your Options, you can specify the cost for each Option using the OptionDetail id

  Option 1:
  - id: 23
  - title: Pepperoni & Mushroom Pizza
  - option_detail_values
    - value: 26
    - option_detail_id: 1

  Option 2:
  - id: 54
  - title: Meatlovers Pizza
  - option_detail_values
    - value: 32
    - option_detail_id: 1

  With this set up, you'll be able to use a Variable with the "Total Cost" of all Options in your final scenario.
  You can display this Variable, or use it to limit the Scenarios generated for your Decision.
  """

  defp option_detail_value_fields() do
    [
      %{
        name: :value,
        info: @value,
        type: :string,
        validation: "none",
        required: true,
        automatic: false,
        immutable: false
      },
      %{
        name: :option_id,
        info: @option_id,
        type: "id",
        required: true,
        validation: "must be part of the same Decision as the OptionDetail"
      },
      %{
        name: :option_detail_id,
        info: @option_detail_id,
        type: "id",
        required: true,
        validation: "must be part of the same Decision as the Option"
      }
    ]
  end

  @doc """
  a list of maps describing all OptionDetailValue schema fields

  Suitable for use with `DocsComposer.schema_fields`.
  """
  def fields() do
    DocsComposer.common_fields([:inserted_at, :updated_at, :decision_id]) ++
      option_detail_value_fields()
  end

  @doc """
  Map describing example records

  Suitable for use with `DocsComposer.schema_examples`.
  """
  def examples() do
    %{
      "Sample 1" => %{
        option_id: 1,
        option_detail_id: 1,
        value: "Thin Crust",
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00"
      },
      "Sample 2" => %{
        option_id: 2,
        option_detail_id: 3,
        value: "Thick Crust",
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00"
      },
      "Update 1" => %{
        option_id: 1,
        option_detail_id: 1,
        value: "New York Style Thin Crust",
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T17:42:36+00:00"
      }
    }
  end

  @doc """
  strings describing each field as well as the general concept of "option_detail_values"
  """
  def strings() do
    option_detail_value_strings = %{
      decision_id: @decision_id,
      mini_tutorial: @mini_tutorial,
      option_detail_id: @option_detail_id,
      option_detail_value: @option_detail_value,
      option_detail: @option_detail_id,
      option_id: @option_id,
      option: @option_id,
      value: @value
    }

    DocsComposer.common_strings() |> Map.merge(option_detail_value_strings)
  end
end
