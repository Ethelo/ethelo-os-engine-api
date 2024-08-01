defmodule Engine.Scenarios.Queries.SolveDump do
  @moduledoc """
  Contains methods that will be delegated to inside solve_dump.
  Used purely to reduce the size of solve_dump.ex
  """

  import Ecto.Query, warn: false
  import EtheloApi.Helpers.QueryHelper

  alias EtheloApi.Repo
  alias EtheloApi.Structure.Decision
  alias Engine.Scenarios.SolveDump

  def valid_filters() do
    [:id, :decision_id, :participant_id, :scenario_set_id]
  end

  def match_query(decision_id, filters) do
    filters = filters |> Map.put(:decision_id, decision_id)
                      |> Map.put_new(:participant_id, nil)

    SolveDump
    |> filter_query(filters, valid_filters())
  end

  @doc """
  Returns the list of SolveDumps for a Decision.

  ## Examples

      iex> list_solve_dumps(solve_dump_id)
      [%Scenario{}, ...]

  """
  def list_solve_dumps(decision, filters \\ %{})
  def list_solve_dumps(%Decision{} = decision, filters), do: list_solve_dumps(decision.id, filters)
  def list_solve_dumps(nil, _), do: raise ArgumentError, message: "you must supply a Decision"
  def list_solve_dumps(decision_id, filters) do
    decision_id |> match_query(filters) |> order_by(desc: :updated_at)
    |> Repo.all
  end

  @doc """
  Returns the matching SolveDumps for a list of Decision ids.

  ## Examples

      iex> match_solve_dumps(solve_dump_id)
      [%Option{}, ...]

  """
  def match_solve_dumps(filters \\ %{}, decision_ids)
  def match_solve_dumps(filters, decision_ids) when is_list(decision_ids) do
    decision_ids = Enum.uniq(decision_ids)

    SolveDump
    |> where([t], t.decision_id in ^decision_ids)
    |> filter_query(filters, valid_filters())
    |> order_by(desc: :updated_at)
    |> Repo.all
  end
  def match_solve_dumps(_, nil), do: raise ArgumentError, message: "you must supply a list of Decision ids"


  @doc """
  Gets the latest SolveDump

  returns nil if latest SolveDump does not exist or does not belong to the specified Decision

  ## Examples

      iex> get_latest_solve_dump(1)
      %SolveDump{}

  """
  def get_latest_solve_dump(decision, filters \\ %{})
  def get_latest_solve_dump(%Decision{} = decision, filters), do: get_latest_solve_dump(decision.id, filters)
  def get_latest_solve_dump(nil, _), do: raise ArgumentError, message: "you must supply a Decision id"
  def get_latest_solve_dump(decision_id, filters) do
    decision_id |> match_query(filters) |> order_by(desc: :updated_at) |> limit(1) |> Repo.one
  end

  @doc """
  Gets a single SolveDump by id

  returns nil if SolveDump does not exist or does not belong to the specified Decision

  ## Examples

      iex> get_solve_dump(123, 1)
      %SolveDump{}

      iex> get_solve_dump(456, 3)
      nil

  """
  def get_solve_dump(id, %Decision{} = decision), do: get_solve_dump(id, decision.id)
  def get_solve_dump(_, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def get_solve_dump(nil, _), do:  raise ArgumentError, message: "you must supply a Solve Dump id"
  def get_solve_dump(id, decision_id) do
    SolveDump |> Repo.get_by(id: id, decision_id: decision_id)
  end

  @doc """
  Creates an solve_dump.

  ## Examples

      iex> upsert_solve_dump(decision, %{error: "no votes", scenario_set_id: 1})
      {:ok, %SolveDump{}}

      iex> upsert_solve_dump(decision, %{error: "no votes"})
      {:error, %Ecto.Changeset{}}

  """
  def upsert_solve_dump(decision, attrs)
  def upsert_solve_dump(%Decision{} = decision, %{} = attrs) do
    %SolveDump{}
    |> SolveDump.create_changeset(attrs, decision)
    |> Repo.insert([upsert: true] |> handle_conflicts([:scenario_set_id]))

  end
  def upsert_solve_dump(_, _), do: raise ArgumentError, message: "you must supply a Decision"


  @doc """
  Deletes a SolveDump.

  ## Examples

      iex> delete_solve_dump(solve_dump, decision_id)
      {:ok, %SolveDump{}, decision_id}

  """
  def delete_solve_dump(id, %Decision{} = decision), do: delete_solve_dump(id, decision.id)
  def delete_solve_dump(%SolveDump{} = solve_dump, decision_id), do: delete_solve_dump(solve_dump.id, decision_id)
  def delete_solve_dump(_, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def delete_solve_dump(nil, _), do:  raise ArgumentError, message: "you must supply a SolveDump id"
  def delete_solve_dump(id, decision_id) do
    existing = get_solve_dump(id, decision_id)
    case existing do
      nil -> {:ok, nil}
      existing -> Repo.delete(existing)
    end
  end

end
