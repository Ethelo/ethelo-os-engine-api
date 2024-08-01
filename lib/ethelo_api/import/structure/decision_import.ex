defmodule EtheloApi.Import.Structure.Decision do
  @moduledoc """
  methods specific to decision imports
  """

  alias EtheloApi.Repo
  alias EtheloApi.Import.ImportSegment
  alias EtheloApi.Import.ImportProcess
  alias EtheloApi.Import.ImportError
  alias EtheloApi.Structure.Decision

  def import_decision(%{} = decision_data, %ImportProcess{} = process) do
    # [:info, :keywords, :language, :slug, :title]

    segment =
      %ImportSegment{key: :decision}
      |> ImportSegment.add_input([decision_data])

    Decision.import_changeset(decision_data)
    |> Repo.insert()
    |> handle_decision_data(segment, decision_data, %ImportProcess{} = process)
  end

  defp handle_decision_data({:error, changeset}, segment, decision_data, process) do
    errors = ImportError.changeset_to_decision_errors(changeset, decision_data)
    segment = ImportSegment.add_errors(segment, errors)

    process = process |> Map.put(:decision, segment) |> Map.put(:valid?, false)
    {:error, process}
  end

  defp handle_decision_data({:ok, decision}, segment, _data, process) do
    segment = segment |> ImportSegment.mark_complete(%{decision.id => decision})

    process = process |> Map.put(:decision, segment) |> Map.put(:decision_id, decision.id)
    {:ok, process}
  end
end
