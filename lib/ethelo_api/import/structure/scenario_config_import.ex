defmodule EtheloApi.Import.Structure.ScenarioConfig do
  @moduledoc """
  methods specific to decision imports
  """

  alias EtheloApi.Structure.ScenarioConfig
  alias EtheloApi.Import.ImportProcess
  alias EtheloApi.Import.ImportSegment

  def process_scenario_configs(%ImportProcess{} = process, decision_import) do
    segment = ImportSegment.create_segment(:scenario_configs, decision_import)

    duplicate_slugs = ImportSegment.list_duplicate_slugs(segment.segment_input)

    changesets =
      for item <- segment.segment_input do
        item |> ScenarioConfig.import_changeset(process.decision_id, duplicate_slugs)
      end

    segment = ImportSegment.process_changesets(segment, changesets)

    process = Map.put(process, :scenario_configs, segment)
    ImportProcess.wrap_process(process, segment)
  end

  def insert_scenario_configs(%ImportProcess{scenario_configs: segment} = process) do
    segment =
      ImportProcess.insert_all_if_valid(ScenarioConfig, segment.processed_by_order, segment)

    segment = ImportSegment.complete_if_valid_insert(segment)

    process = Map.put(process, :scenario_configs, segment)
    ImportProcess.wrap_process(process, segment)
  end
end
