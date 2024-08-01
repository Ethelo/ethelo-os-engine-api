defmodule EtheloApi.Import.Structure.OptionCategory do
  @moduledoc """
  methods specific to decision imports
  """

  alias EtheloApi.Import.ImportProcess
  alias EtheloApi.Import.ImportSegment
  alias EtheloApi.Structure.OptionCategory

  def process_option_categories(%ImportProcess{} = process, decision_import) do
    segment = ImportSegment.create_segment(:option_categories, decision_import)

    duplicate_slugs = ImportSegment.list_duplicate_slugs(segment.segment_input)

    changesets =
      for item <- segment.segment_input do
        item |> OptionCategory.import_changeset(process.decision_id, duplicate_slugs)
      end

    segment = ImportSegment.process_changesets(segment, changesets)

    process = Map.put(process, :option_categories, segment)

    ImportProcess.wrap_process(process, segment)
  end

  def insert_option_categories(%ImportProcess{option_categories: segment} = process) do
    segment =
      ImportProcess.insert_all_if_valid(OptionCategory, segment.processed_by_order, segment,
        returning: [:id, :slug, :scoring_mode, :decision_id]
      )

    process = Map.put(process, :option_categories, segment)
    ImportProcess.wrap_process(process, segment)
  end

  def update_option_categories(%ImportProcess{option_categories: segment} = process) do
    segment = process_associations(segment.inserted_by_id, process, segment)

    options = [returning: [:id, :slug], stale_error_field: :id]

    result =
      ImportProcess.update_multi_if_valid(segment.processed_by_order, options)

    segment = ImportSegment.process_update_multi(segment, result)

    segment = ImportSegment.complete_if_valid_update(segment)

    process = Map.put(process, :option_categories, segment)
    ImportProcess.wrap_process(process, segment)
  end

  def process_associations(inserted_by_id, process, segment) do
    association_list = %{
      "default_high_option_id" => :options,
      "default_low_option_id" => :options,
      "primary_detail_id" => :option_details
    }

    by_order = ImportSegment.index_id_to_order(segment, inserted_by_id)

    updated_changesets =
      for {order, inserted_item} <- by_order do
        input_item = Map.get(segment.input_by_order, order)

        assocs =
          ImportProcess.build_association_data(process, input_item, association_list)

        OptionCategory.import_assoc_changeset(inserted_item, assocs)
      end

    ImportSegment.process_changesets(segment, updated_changesets)
  end
end
