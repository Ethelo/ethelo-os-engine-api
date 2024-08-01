defmodule EtheloApi.Import.Structure.OptionFilter do
  @moduledoc """
  methods specific to decision imports
  """

  alias EtheloApi.Import.ImportProcess
  alias EtheloApi.Import.ImportSegment
  alias EtheloApi.Structure.OptionFilter

  def process_option_filters(%ImportProcess{} = process, decision_import) do
    segment = ImportSegment.create_segment(:option_filters, decision_import)

    duplicate_slugs = ImportSegment.list_duplicate_slugs(segment.segment_input)

    changesets =
      for item <- segment.segment_input do
        item |> OptionFilter.import_changeset(process.decision_id, duplicate_slugs)
      end

    segment = ImportSegment.process_changesets(segment, changesets)
    process = Map.put(process, :option_filters, segment)

    ImportProcess.wrap_process(process, segment)
  end

  def insert_option_filters(%ImportProcess{option_filters: segment} = process) do
    segment = process_associations(segment.processed_by_order, process, segment)

    segment = ImportProcess.insert_all_if_valid(OptionFilter, segment.processed_by_order, segment)

    segment = ImportSegment.complete_if_valid_insert(segment)

    process = Map.put(process, :option_filters, segment)
    ImportProcess.wrap_process(process, segment)
  end

  def process_associations(processed_by_order, process, segment) do
    association_list = %{
      "option_detail_id" => :option_details,
      "option_category_id" => :option_categories
    }

    updated_changesets =
      for {order, changeset} <- processed_by_order do
        input_item = Map.get(segment.input_by_order, order)

        assocs =
          ImportProcess.build_association_data(process, input_item, association_list)

        attrs = Map.merge(changeset.changes, assocs)

        OptionFilter.import_assoc_changeset(attrs, process.decision_id)
      end

    ImportSegment.process_changesets(segment, updated_changesets)
  end
end
