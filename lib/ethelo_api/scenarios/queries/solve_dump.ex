defmodule EtheloApi.Scenarios.Queries.SolveDump do
  @moduledoc """
  Contains methods that will be delegated to inside EtheloApi.Scenarios.
  """

  alias EtheloApi.Repo
  alias EtheloApi.Scenarios.SolveDump
  alias EtheloApi.Scenarios.ScenarioSet
  import Ecto.Query, warn: false

  @doc """
  Returns the SolveDumps for a ScenarioSet.

  ## Examples

      iex> get_solve_dump(scenario_set_id)
      %SolveDump

  """
  def get_solve_dump(scenario_set)

  def get_solve_dump(%ScenarioSet{id: id}), do: get_solve_dump(id)

  def get_solve_dump(nil), do: raise(ArgumentError, message: "you must supply a ScenarioSet")

  def get_solve_dump(scenario_set_id) do
    SolveDump
    |> where([t], t.scenario_set_id == ^scenario_set_id)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Upserts a SolveDump.

  ## Examples

      iex> upsert_solve_dump( %{scenario_set_id: 1})
      {:ok, %SolveDump{}}

      iex> upsert_solve_dump(d %{scenario_set_id: 0}, decision)
      {:error, %Ecto.Changeset{}}
  """

  def upsert_solve_dump(attrs)

  def upsert_solve_dump(%{} = attrs) do
    SolveDump.upsert_changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace_all_except, [:id, :decision_id, :scenario_set_id]},
      conflict_target: [:scenario_set_id],
      returning: true
    )
  end

  def upsert_solve_dump(_, _),
    do: raise(ArgumentError, message: "you must supply a ScenarioSet Id")
end
