defmodule EtheloApi.Import.Structure.Calculation do
  @moduledoc """
  methods specific to decision imports
  """

  alias EtheloApi.Import.ImportProcess
  alias EtheloApi.Import.ImportSegment
  alias EtheloApi.Structure.Calculation

  def process_calculations(%ImportProcess{} = process, decision_import) do
    segment = ImportSegment.create_segment(:calculations, decision_import)

    duplicate_slugs = ImportSegment.list_duplicate_slugs(segment.segment_input)

    changesets =
      for item <- segment.segment_input do
        item |> Calculation.import_changeset(process.decision_id, duplicate_slugs)
      end

    segment = ImportSegment.process_changesets(segment, changesets)
    process = Map.put(process, :calculations, segment)

    ImportProcess.wrap_process(process, segment)
  end

  def insert_calculations(%ImportProcess{calculations: segment} = process) do
    options = [returning: [:id, :slug, :expression, :decision_id]]

    segment =
      ImportProcess.insert_all_if_valid(Calculation, segment.processed_by_order, segment, options)

    process = Map.put(process, :calculations, segment)
    ImportProcess.wrap_process(process, segment)
  end

  def update_calculations(%ImportProcess{calculations: segment} = process) do
    segment = process_associations(segment.inserted_by_id, segment)

    options = [returning: [:id, :slug], stale_error_field: :id]
    result = ImportProcess.update_multi_if_valid(segment.processed_by_order, options)

    segment = ImportSegment.process_update_multi(segment, result)

    segment = ImportSegment.complete_if_valid_update(segment)

    process = Map.put(process, :calculations, segment)
    ImportProcess.wrap_process(process, segment)
  end

  def process_associations(inserted_by_id, segment) do
    updated_changesets =
      for {_, inserted_item} <- inserted_by_id do
        # pass no attrs as variables will be parsed from expression
        Calculation.import_assoc_changeset(inserted_item)
      end

    ImportSegment.process_changesets(segment, updated_changesets)
  end
end
