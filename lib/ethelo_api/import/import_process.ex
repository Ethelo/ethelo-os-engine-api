defmodule EtheloApi.Import.ImportProcess do
  @moduledoc """
  Multi-stage import processor
  """

  use StructAccess

  @derive {Inspect, only: [:valid?, :complete?]}

  require Logger

  alias EtheloApi.Repo
  alias EtheloApi.Import.ImportSegment
  alias EtheloApi.Import.ImportProcess
  alias EtheloApi.Import.ImportError
  alias Ecto.Changeset

  alias EtheloApi.Import.Structure.Decision, as: DecisionImport
  alias EtheloApi.Import.Structure.Calculation, as: CalculationImport
  alias EtheloApi.Import.Structure.Constraint, as: ConstraintImport
  alias EtheloApi.Import.Structure.Criteria, as: CriteriaImport
  alias EtheloApi.Import.Structure.Option, as: OptionImport
  alias EtheloApi.Import.Structure.OptionCategory, as: OptionCategoryImport
  alias EtheloApi.Import.Structure.OptionDetail, as: OptionDetailImport
  alias EtheloApi.Import.Structure.OptionDetailValue, as: OptionDetailValueImport
  alias EtheloApi.Import.Structure.OptionFilter, as: OptionFilterImport
  alias EtheloApi.Import.Structure.Variable, as: VariableImport
  alias EtheloApi.Import.Structure.ScenarioConfig, as: ScenarioConfigImport

  defstruct [
    :complete?,
    :decision_id,
    :input,
    :valid?,
    :input_error,

    # segments
    :calculations,
    :constraints,
    :criterias,
    :decision,
    :options,
    :option_categories,
    :option_details,
    :option_detail_values,
    :option_filters,
    :scenario_configs,
    :variables
  ]

  def segment_names() do
    [
      :calculations,
      :constraints,
      :criterias,
      :decision,
      :options,
      :option_categories,
      :option_details,
      :option_detail_values,
      :option_filters,
      :scenario_configs,
      :variables
    ]
  end

  def build_from_json(json_export, decision_data) do
    decode_json_import(json_export) |> build_if_valid(decision_data)
  end

  def build_if_valid({:ok, input}, decision_data) when input == %{} do
    {:error, "is invalid"} |> build_if_valid(decision_data)
  end

  def build_if_valid({:error, reason}, _) do
    ImportError.add_input_error(reason)
  end

  def build_if_valid({:ok, input}, decision_data) do
    case build(input, decision_data) do
      {:ok, process} ->
        decision = get_in(process, [:decision, :completed_by_id, process.decision_id])
        {:ok, decision}

      {:error, process} ->
        {:error, process}
    end
  end

  def build(input, decision_data) do
    EtheloApi.Repo.transaction(
      fn ->
        case do_build(input, decision_data) do
          {:ok, process} -> process
          {:error, process} -> Repo.rollback(process)
        end
      end,
      timeout: :infinity
    )
  end

  def do_build(input, decision_data) do
    process = %ImportProcess{valid?: true, complete?: false, input: input}

    with(
      {:ok, process} <- DecisionImport.import_decision(decision_data, process),
      {:ok, process} <- process_changesets(input, process),
      {:ok, process} <- insert_with_associations(input, process)
    ) do
      Logger.debug(fn -> "Import Complete, ensure filters and vars" end)

      EtheloApi.Structure.ensure_filters_and_vars(process.decision_id)

      {:ok, Map.put(process, :complete?, true)}
    end
  end

  def process_changesets(input, process) do
    {_, process} = ScenarioConfigImport.process_scenario_configs(process, input)
    {_, process} = CriteriaImport.process_criterias(process, input)
    {_, process} = OptionDetailImport.process_option_details(process, input)
    {_, process} = OptionCategoryImport.process_option_categories(process, input)
    {_, process} = OptionImport.process_options(process, input)
    {_, process} = OptionFilterImport.process_option_filters(process, input)
    {_, process} = VariableImport.process_variables(process, input)
    {_, process} = CalculationImport.process_calculations(process, input)
    {_, process} = ConstraintImport.process_constraints(process, input)
    check_process(process)
  end

  def insert_with_associations(input, process) do
    with(
      {:ok, process} <-
        ScenarioConfigImport.insert_scenario_configs(process) |> check_process(),
      {:ok, process} <- CriteriaImport.insert_criterias(process) |> check_process(),
      {:ok, process} <- OptionDetailImport.insert_option_details(process) |> check_process(),
      {:ok, process} <-
        OptionCategoryImport.insert_option_categories(process) |> check_process(),
      {:ok, process} <- OptionImport.insert_options(process) |> check_process(),
      {:ok, process} <-
        OptionDetailValueImport.insert_option_detail_values(process, input) |> check_process(),
      {:ok, process} <- OptionFilterImport.insert_option_filters(process) |> check_process(),
      {:ok, process} <- VariableImport.insert_variables(process) |> check_process(),
      {:ok, process} <- CalculationImport.insert_calculations(process) |> check_process(),
      {:ok, process} <- ConstraintImport.insert_constraints(process) |> check_process(),
      {:ok, process} <-
        OptionCategoryImport.update_option_categories(process) |> check_process(),
      {:ok, process} <- CalculationImport.update_calculations(process) |> check_process()
    ) do
      Logger.debug(fn -> "Inserts Complete" end)
      {:ok, process}
    end
  end

  def insert_all_if_valid(
        schema,
        changesets,
        segment,
        options \\ [returning: [:id, :slug, :decision_id]]
      )

  def insert_all_if_valid(_, _, %{valid?: false} = segment, _), do: segment

  def insert_all_if_valid(schema, changesets, segment, options) when is_map(changesets),
    do: insert_all_if_valid(schema, Map.values(changesets), segment, options)

  def insert_all_if_valid(_, changesets, segment, _) when changesets == [],
    do: segment

  def insert_all_if_valid(schema, [%Changeset{} | _] = changesets, segment, options) do
    data =
      for changeset <- changesets do
        Map.merge(default_values(schema), changeset.changes)
      end

    result = ImportProcess.do_insert_all(schema, data, options)
    ImportSegment.process_insert_all(segment, result, :slug)
  end

  def do_insert_all(schema, data, options) when is_list(data) and is_list(options) do
    try do
      inserts = Repo.insert_all(schema, data, options)
      {:ok, inserts}
    rescue
      pg_error in Postgrex.Error ->
        {:error, pg_error}

      error ->
        # trigger by passing table name instead of schema into insert all
        {:error, error}
    end
  end

  def update_multi_if_valid(changesets_by_order, options) when is_list(options) do
    for {order, changeset} <- changesets_by_order, reduce: Ecto.Multi.new() do
      multi ->
        if changeset.changes == %{} do
          Ecto.Multi.run(multi, order, fn _repo, _state -> {:ok, changeset.data} end)
        else
          Ecto.Multi.update(multi, order, changeset, options)
        end
    end
    |> EtheloApi.Repo.transaction()
  end

  def build_association_data(%{} = process, %{} = input_item, association_list) do
    for {field, segment_key} <- association_list, into: %{} do
      input_association_id = Map.get(input_item, field)
      new_id = get_in(process, [segment_key, :input_id_to_db_id, input_association_id])
      {String.to_existing_atom(field), new_id}
    end
  end

  def wrap_process(process, segment) do
    case segment.valid? do
      true ->
        {:ok, process}

      false ->
        {:error, process |> Map.put(:valid?, false)}
    end
  end

  def check_process({_, %{valid?: false} = process}), do: {:error, process}

  def check_process({_, process}), do: check_process(process)

  def check_process(%{valid?: false} = process), do: {:error, process}

  def check_process(process) do
    if ImportError.invalid_segments(process) != [] do
      {:error, Map.put(process, :valid?, false)}
    else
      {:ok, process}
    end
  end

  def default_values(schema) do
    Map.take(schema.__struct__(), schema.__schema__(:fields))
    |> Enum.filter(fn {_k, v} -> !is_nil(v) end)
    |> Enum.into(%{})
  end

  defp decode_json_import(nil), do: {:ok, %{}}

  defp decode_json_import(json) do
    case Jason.decode(json) do
      {:ok, input} ->
        parsed =
          input
          |> Map.get("decision")
          |> ImportProcess.atomize_input_keys()
          |> Map.take(segment_names())

        {:ok, parsed}

      {:error, _} ->
        {:ok, %{}}
    end
  end

  def atomize_input_keys(nil), do: %{}

  def atomize_input_keys(import) do
    allowed_strings = segment_names() |> Enum.map(&to_string/1)

    for {k, v} <- import, into: %{} do
      if k in allowed_strings do
        {String.to_existing_atom(k), v}
      else
        {k, v}
      end
    end
  end
end
