defmodule EtheloApi.Import.Structure.OptionDetail do
  @moduledoc """
  methods specific to decision imports
  """

  alias EtheloApi.Import.ImportProcess
  alias EtheloApi.Import.ImportSegment
  alias EtheloApi.Structure.OptionDetail

  def process_option_details(%ImportProcess{} = process, decision_import) do
    segment = ImportSegment.create_segment(:option_details, decision_import)

    duplicate_slugs = ImportSegment.list_duplicate_slugs(segment.segment_input)

    changesets =
      for item <- segment.segment_input do
        item |> OptionDetail.import_changeset(process.decision_id, duplicate_slugs)
      end

    segment = ImportSegment.process_changesets(segment, changesets)
    process = Map.put(process, :option_details, segment)

    ImportProcess.wrap_process(process, segment)
  end

  def insert_option_details(%ImportProcess{option_details: segment} = process) do
    segment = ImportProcess.insert_all_if_valid(OptionDetail, segment.processed_by_order, segment)

    segment = ImportSegment.complete_if_valid_insert(segment)

    process = Map.put(process, :option_details, segment)
    ImportProcess.wrap_process(process, segment)
  end
end
