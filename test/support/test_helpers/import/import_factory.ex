defmodule EtheloApi.TestHelper.ImportFactory do
  @moduledoc """
  Generic helpers used in import tests
  """

  import EtheloApi.Structure.Factory
  alias EtheloApi.Import.ImportSegment
  alias EtheloApi.Import.ImportProcess

  def load_support_file(filename) do
    File.read!(Path.join("test/support/json", filename))
  end

  def get_input() do
    json = load_support_file("pizza/decision.json")
    parse_import(json)
  end

  def parse_import(json) do
    {:ok, input} = Jason.decode(json)

    %{"decision" => elixir_import} = input

    ImportProcess.atomize_input_keys(elixir_import)
  end

  def setup_decision(%{process: process} = context) do
    decision = create_decision()
    process = Map.put(process, :decision_id, decision.id)
    context |> Map.put(:process, process) |> Map.put(:decision, decision)
  end

  def setup_option_categories(%{process: process, decision: decision}) do
    segment_input = get_in(process, [:input, :option_categories])

    lists =
      for {input_item, order} <- Enum.with_index(segment_input),
          reduce: %{index: %{}, inserted: %{}} do
        %{index: index, inserted: inserted} ->
          %{option_category: option_category} =
            create_option_category(decision, %{
              slug: input_item["slug"],
              scoring_mode: input_item["scoring_mode"] |> String.to_existing_atom()
            })

          %{
            index: Map.put(index, input_item["id"], option_category.id),
            inserted: Map.put(inserted, order, option_category)
          }
      end

    inserted = lists[:inserted] |> Map.values()

    create_segment(process, :option_categories, segment_input, lists[:index], inserted)
  end

  def setup_options(%{process: process, decision: decision}) do
    segment_input = get_in(process, [:input, :options])

    index =
      for input_item <- segment_input, into: %{} do
        %{option: option} =
          create_option(decision, %{slug: input_item["slug"]})

        {input_item["id"], option.id}
      end

    create_segment(process, :options, segment_input, index)
  end

  def setup_option_details(%{process: process, decision: decision}) do
    segment_input = get_in(process, [:input, :option_details])

    index =
      for input_item <- segment_input, into: %{} do
        attrs = %{
          slug: input_item["slug"],
          format: input_item["format"] |> String.to_existing_atom()
        }

        %{option_detail: option_detail} =
          create_option_detail(decision, attrs)

        {input_item["id"], option_detail.id}
      end

    create_segment(process, :option_details, segment_input, index)
  end

  def setup_option_filters(%{process: process, decision: decision}) do
    segment_input = get_in(process, [:input, :option_filters])

    index =
      for input_item <- segment_input, into: %{} do
        attrs = %{slug: input_item["slug"], match_mode: input_item["match_mode"]}

        %{option_filter: option_filter} =
          cond do
            input_item["match_mode"] == "all_options" ->
              create_all_options_filter(decision)

            is_nil(input_item["option_category_id"]) ->
              create_option_detail_filter(decision, attrs)

            true ->
              create_option_category_filter(decision, attrs)
          end

        {input_item["id"], option_filter.id}
      end

    create_segment(process, :option_filters, segment_input, index)
  end

  def setup_variables(%{process: process, decision: decision}) do
    segment_input = get_in(process, [:input, :variables])

    index =
      for input_item <- segment_input, into: %{} do
        attrs = %{slug: input_item["slug"]}

        %{variable: variable} = create_detail_variable(decision, attrs)

        {input_item["id"], variable.id}
      end

    create_segment(process, :variables, segment_input, index)
  end

  def setup_calculations(%{process: process, decision: decision}) do
    segment_input = get_in(process, [:input, :calculations])

    list_base = %{index: %{}, inserted: %{}}

    lists =
      for {input_item, order} <- Enum.with_index(segment_input), reduce: list_base do
        %{index: index, inserted: inserted} ->
          calculation =
            create_calculation(decision, %{
              slug: input_item["slug"],
              expression: input_item["expression"]
            })
            |> Map.get(:calculation)

          %{
            index: Map.put(index, input_item["id"], calculation.id),
            inserted: Map.put(inserted, order, calculation)
          }
      end

    inserted = lists[:inserted] |> Map.values()

    create_segment(process, :calculations, segment_input, lists[:index], inserted)
  end

  def create_segment(process, segment_key, segment_input, index, inserted \\ []) do
    segment = ImportSegment.create_segment(segment_key, %{})

    segment =
      segment
      |> Map.put(:input_id_to_db_id, index)
      |> Map.put(:input_by_order, index_by_order(segment_input))
      |> Map.put(:inserted_by_id, index_by_id(inserted))

    process |> Map.put(segment_key, segment)
  end

  def index_by_id(records) do
    for item <- records, into: %{}, do: {Map.get(item, :id), item}
  end

  def index_by_order(list) do
    for {item, order} <- Enum.with_index(list), into: %{}, do: {order, item}
  end
end
