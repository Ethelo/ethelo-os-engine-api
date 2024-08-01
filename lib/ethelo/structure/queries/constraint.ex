defmodule EtheloApi.Structure.Queries.Constraint do
  @moduledoc """
  Contains methods that will be delegated to inside structure.
  Used purely to reduce the size of structure.ex
  """

  import Ecto.Query, warn: false
  import EtheloApi.Helpers.QueryHelper

  alias EtheloApi.Repo
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Constraint
  alias EtheloApi.Structure.Decision

  def valid_filters() do
    [:slug, :id, :enabled, :decision_id, :variable_id, :calculation_id, :option_filter_id]
  end

  @doc """
  private method to start querying with acceptable preloads
  """
  def base_query() do
    Constraint
  end

  def match_query(decision_id, filters) do
    filters = Map.put(filters, :decision_id, decision_id)

    Constraint
    |> filter_query(filters, valid_filters())
  end

  @doc """
  Returns the list of Constraints for a Decision.

  ## Examples

      iex> list_constraints(decision_id)
      [%Constraint{}, ...]

  """
  def list_constraints(decision, filters \\ %{})
  def list_constraints(%Decision{} = decision, filters), do: list_constraints(decision.id, filters)
  def list_constraints(nil, _), do: raise ArgumentError, message: "you must supply a Decision"
  def list_constraints(decision_id, filters) do
    decision_id |> match_query(filters) |> Repo.all
  end

  @doc """
  Returns a list of matching Constraints for a list of Decision ids.

  ## Examples

      iex> match_constraints(decision_id)
      [%Constraint{}, ...]

  """
  def match_constraints(filters \\ %{}, decision_ids)
  def match_constraints(filters, decision_ids) when is_list(decision_ids) do
    decision_ids = Enum.uniq(decision_ids)

    Constraint
    |> where([t], t.decision_id in ^decision_ids)
    |> filter_query(filters, valid_filters())
    |> Repo.all
  end
  def match_constraints(_, nil), do: raise ArgumentError, message: "you must supply a list of Decision ids"

  @doc """
  Gets a single Constraint.

  returns nil if Constraint does not exist or does not belong to the specified Decision

  ## Examples

      iex> get_constraint(123, 1)
      %Constraint{}

      iex> get_constraint(456, 3)
      nil

  """
  def get_constraint(id, %Decision{} = decision), do: get_constraint(id, decision.id)
  def get_constraint(_, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def get_constraint(nil, _), do:  raise ArgumentError, message: "you must supply a Constraint id"
  def get_constraint(id, decision_id) do
    base_query() |> Repo.get_by(id: id, decision_id: decision_id)
  end

  @doc """
  Creates an constraint.

  ## Examples

      iex> create_constraint(decision, %{title: "This is my title"})
      {:ok, %Constraint{}}

      iex> create_constraint(decision, %{title: " "})
      {:error, %Ecto.Changeset{}}

  """
  def create_constraint(%Decision{} = decision, %{} = attrs) do
    %Constraint{}
    |> Constraint.create_changeset(attrs, decision)
    |> Repo.insert()
    |> Structure.maybe_update_structure_hash(decision, %{new: true})

  end
  def create_constraint(_, _), do: raise ArgumentError, message: "you must supply a Decision"

  @doc """
  Updates a Constraint.
  Note: this method will not change the Decision a Constraint belongs to.

  ## Examples

      iex> update_constraint(constraint, %{field: new_value})
      {:ok, %Constraint{}}

      iex> update_constraint(constraint, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_constraint(%Constraint{} = constraint, %{} = attrs) do
    changeset = constraint |> Constraint.update_changeset(attrs)
    changeset
    |> Repo.update()
    |> Structure.maybe_update_structure_hash(constraint.decision_id, changeset.changes)
  end

  @doc """
  Deletes a Constraint.

  ## Examples

      iex> delete_constraint(constraint, decision_id)
      {:ok, %Constraint{}, decision_id}

  """
  def delete_constraint(id, %Decision{} = decision), do: delete_constraint(id, decision.id)
  def delete_constraint(%Constraint{} = constraint, decision_id), do: delete_constraint(constraint.id, decision_id)
  def delete_constraint(_, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def delete_constraint(nil, _), do:  raise ArgumentError, message: "you must supply a Constraint id"
  def delete_constraint(id, decision_id) do
    id
    |> get_constraint(decision_id)
    |> case do
      nil -> {:ok, nil}
      constraint ->
        Repo.delete(constraint)
        |> Structure.maybe_update_structure_hash(decision_id, %{deleted: true})

    end
  end

end
