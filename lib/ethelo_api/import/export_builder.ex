defmodule EtheloApi.Import.ExportBuilder do
  @moduledoc """
  Creates a JSON export of all decision data suitable for import

  Excludes internal / protected fields
  Loads only required fields as maps instead of structures for efficenicy
  """
  alias EtheloApi.Repo
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Import.ImportProcess
  alias EtheloApi.Import.ImportError

  import EtheloApi.Helpers.ValidationHelper, only: [validation_message: 3]
  import Ecto.Query

  def export_decision(%Decision{id: decision_id} = decision) do
    decision_base = Map.take(decision, Decision.export_fields())

    content =
      decision_base
      |> Map.put(:exported_at, DateTime.utc_now())
      |> Map.put(:calculations, export_data(EtheloApi.Structure.Calculation, decision_id))
      |> Map.put(:constraints, export_data(EtheloApi.Structure.Constraint, decision_id))
      |> Map.put(:criterias, export_data(EtheloApi.Structure.Criteria, decision_id))
      |> Map.put(:option_categories, export_data(EtheloApi.Structure.OptionCategory, decision_id))
      |> Map.put(:option_details, export_data(EtheloApi.Structure.OptionDetail, decision_id))
      |> Map.put(
        :option_detail_values,
        export_data(EtheloApi.Structure.OptionDetailValue, decision_id)
      )
      |> Map.put(:option_filters, export_data(EtheloApi.Structure.OptionFilter, decision_id))
      |> Map.put(:options, export_data(EtheloApi.Structure.Option, decision_id))
      |> Map.put(:scenario_configs, export_data(EtheloApi.Structure.ScenarioConfig, decision_id))
      |> Map.put(:variables, export_data(EtheloApi.Structure.Variable, decision_id))

    %{decision: content} |> Jason.encode()
  end

  def export_data(schema, decision_id) do
    field_list = schema.export_fields()

    schema
    |> where([s], s.decision_id == ^decision_id)
    |> select([s], map(s, ^field_list))
    |> Repo.all()
  end

  def copy_decision(%Decision{} = decision, decision_data) do
    result =
      with({:ok, json_export} <- export_decision(decision)) do
        ImportProcess.build_from_json(json_export, decision_data)
      end

    case result do
      {:ok, decision} ->
        {:ok, decision}

      {:error, %ImportProcess{} = process} ->
        {:error, ImportError.summarize_errors(process)}

      {:error, reason} ->
        IO.inspect(reason, label: "reason")
        message = validation_message("Unexpected Error, Copy Failed", :decision_id, :unknown)

        {:error, [message]}
    end
  end
end
