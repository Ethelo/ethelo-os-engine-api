defmodule EtheloApi.Import.Structure.Criteria do
  @moduledoc """
  methods specific to decision imports
  """

  alias EtheloApi.Import.ImportProcess
  alias EtheloApi.Import.ImportSegment
  alias EtheloApi.Structure.Criteria

  def process_criterias(%ImportProcess{} = process, decision_import) do
    segment = ImportSegment.create_segment(:criterias, decision_import)

    duplicate_slugs = ImportSegment.list_duplicate_slugs(segment.segment_input)

    changesets =
      for item <- segment.segment_input do
        item |> Criteria.import_changeset(process.decision_id, duplicate_slugs)
      end

    segment = ImportSegment.process_changesets(segment, changesets)

    process = Map.put(process, :criterias, segment)
    ImportProcess.wrap_process(process, segment)
  end

  def insert_criterias(%ImportProcess{criterias: segment} = process) do
    segment = ImportProcess.insert_all_if_valid(Criteria, segment.processed_by_order, segment)
    segment = ImportSegment.complete_if_valid_insert(segment)

    process = Map.put(process, :criterias, segment)
    ImportProcess.wrap_process(process, segment)
  end
end
