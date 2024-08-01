defmodule EtheloApi.Import.Structure.OptionDetailValue do
  @moduledoc """
  methods specific to decision imports
  """

  alias EtheloApi.Import.ImportProcess
  alias EtheloApi.Import.ImportSegment
  alias EtheloApi.Structure.OptionDetailValue

  def insert_option_detail_values(%ImportProcess{} = process, decision_import) do
    segment = ImportSegment.create_segment(:option_detail_values, decision_import)

    association_list = %{"option_detail_id" => :option_details, "option_id" => :options}

    changesets =
      for input_item <- segment.segment_input do
        assocs = ImportProcess.build_association_data(process, input_item, association_list)

        data = Map.put(assocs, :value, input_item["value"])
        OptionDetailValue.import_assoc_changeset(data, process.decision_id)
      end

    segment = ImportSegment.process_changesets(segment, changesets)

    segment = insert_all_if_valid(OptionDetailValue, segment.processed_by_order, segment)

    segment = ImportSegment.complete_if_valid_insert(segment)

    process = Map.put(process, :option_detail_values, segment)
    ImportProcess.wrap_process(process, segment)
  end

  def insert_all_if_valid(_, _, %{valid?: false} = segment), do: segment

  def insert_all_if_valid(_, processed_by_order, segment) when processed_by_order == %{},
    do: segment

  def insert_all_if_valid(schema, processed_by_order, segment) do
    data = processed_by_order |> Map.values() |> Enum.map(& &1.changes)

    result = ImportProcess.do_insert_all(schema, data, returning: true)
    ImportSegment.process_insert_all(segment, result, false)
  end
end
