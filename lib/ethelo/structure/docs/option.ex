defmodule EtheloApi.Structure.Docs.Option do
  @moduledoc "Central repository for documentation strings about Options."

  require DocsComposer
  alias EtheloApi.Structure.Docs.OptionDetailValue

  @decision_id "Unique identifier for the Decision the Option belongs to. All Options are associated with a single Decision."

  @option "Options are the choices that a make up a Decision solution. Your solution may include multiple Options."

  @title "Name of Option. Used to generate slug if none supplied"
  @results_title "Name of Option to display in results. Reverts to title if not entered"
  @info "Informative text describing the Option."
  @enabled """
  A boolean that indicates if the Option should be included in the Ethelo calculation. Defaults to "true".

  This is a convenience setting to allow you to quickly iterate on a Decision setup without having to recreate Options.
  """

  @determinative "Boolean to indicate if the inclusion of the option should be based on if it has positive votes"

  @option_category_id "The OptionCategory to source the value from. Options must define an OptionCategory."

  @option_category "OptionCategories are used to specify the importance of Options. Each group has a specific \"weight\" applied, making the Options more or less important when calculating the best result."

  defp option_fields() do
    [
     %{name: :title, info: @title, type: :string, validation: "Must include at least one word", required: true, automatic: false, immutable: false},
     %{name: :results_title, info: @results_title, type: :string, validation: "Must include at least one word", required: false, automatic: false, immutable: false},
     %{name: :info, info: @info, type: "html", required: false, automatic: false, immutable: false},
     %{name: :determinative, info: @determinative, type: :boolean , required: false, default: false},
     %{name: :enabled, info: @enabled, type: :boolean , required: false, default: true},
     %{name: :option_category_id, match_value: @option_category_id, type: "id", required: "true", validation: "must be part of the same Decision."},
     %{name: :decision_id, info: @decision_id, type: "id" , required: true},
   ]
  end

  @doc """
  a list of maps describing all option schema fields

  Suitable for use with `DocsComposer.schema_fields`.
  """
  def fields() do
    DocsComposer.common_fields([:id, :slug, :sort, :deleted, :inserted_at, :updated_at]) ++ option_fields()
  end

  @doc """
  Map describing example records

  Suitable for use with `DocsComposer.schema_examples`.
  """
  def examples() do
    %{
      "Sample 1" => %{
        id: 1,
        enabled: true,
        deleted: false,
        determinative: false,
        title: "Peter's Pizza Palace",
        results_title: "PPP",
        slug: "peter-s-pizza-palace",
        info: "Brilliant thin crust pizza",
        decision_id: 1,
        option_category: 1,
        sort: 1,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
      },
      "Sample 2" => %{
        id: 2,
        enabled: true,
        results_title: "",
        deleted: false,
        determinative: false,
        option_category: 1,
        title: "Courtney's Chicago Deep Dish",
        slug: "courtney-s-chicago",
        info: "Deep Dish and Desserts",
        decision_id: 1,
        sort: 2,
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
      },
      "Update 1" => %{
         id: 1,
         enabled: true,
         deleted: false,
         determinative: true,
         title: "Peter's Pizza Palace",
         results_title: "",
         slug: "peters-pizza-palace",
         info: "Brilliant thin crust pizza. No sides available",
         decision_id: 1,
         option_category: 1,
         sort: 3,
         inserted_at: "2017-05-05T16:48:16+00:00",
         updated_at: "2017-05-05T17:42:36+00:00",
       }
    }
  end

  @doc """
  strings describing each field as well as the general concept of "options"
  """
  def strings() do
    option_strings = %{
      option: @option,
      info: @info,
      enabled: @enabled,
      results_title: @results_title,
      title: @title,
      determinative: @determinative,
      decision_id: @decision_id,
      value: OptionDetailValue.strings.value,
      option_id: OptionDetailValue.strings.option_id,
      option_detail_id: OptionDetailValue.strings.option_detail_id,
      option_detail_value: OptionDetailValue.strings.option_detail_value,
      option_category: @option_category,
      option_category_id: @option_category_id,
    }
    DocsComposer.common_strings() |> Map.merge(option_strings)
  end

end
