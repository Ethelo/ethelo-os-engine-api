defmodule EtheloApi.Import.Structure.Constraint do
  @moduledoc """
  methods specific to decision imports
  """

  alias EtheloApi.Import.ImportProcess
  alias EtheloApi.Import.ImportSegment
  alias EtheloApi.Structure.Constraint

  def process_constraints(%ImportProcess{} = process, decision_import) do
    segment = ImportSegment.create_segment(:constraints, decision_import)

    duplicate_slugs = ImportSegment.list_duplicate_slugs(segment.segment_input)

    changesets =
      for item <- segment.segment_input do
        item |> Constraint.import_changeset(process.decision_id, duplicate_slugs)
      end

    segment = ImportSegment.process_changesets(segment, changesets)
    process = Map.put(process, :constraints, segment)

    ImportProcess.wrap_process(process, segment)
  end

  def insert_constraints(%ImportProcess{constraints: segment} = process) do
    segment = process_associations(segment.processed_by_order, process, segment)

    segment = ImportProcess.insert_all_if_valid(Constraint, segment.processed_by_order, segment)

    segment = ImportSegment.complete_if_valid_insert(segment)

    process = Map.put(process, :constraints, segment)
    ImportProcess.wrap_process(process, segment)
  end

  def process_associations(processed_by_order, process, segment) do
    association_list = %{
      "variable_id" => :variables,
      "calculation_id" => :calculations,
      "option_filter_id" => :option_filters
    }

    updated_changesets =
      for {order, changeset} <- processed_by_order do
        input_item = Map.get(segment.input_by_order, order)

        assocs =
          ImportProcess.build_association_data(process, input_item, association_list)

        attrs = Map.merge(changeset.changes, assocs)

        Constraint.import_assoc_changeset(attrs, process.decision_id)
      end

    ImportSegment.process_changesets(segment, updated_changesets)
  end
end
