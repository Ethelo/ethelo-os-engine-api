defmodule EtheloApi.Structure.Queries.Criteria do
  @moduledoc """
  Contains methods that will be delegated to inside structure.
  Used purely to reduce the size of structure.ex
  """

  import Ecto.Query, warn: false
  import EtheloApi.Helpers.EctoHelper
  import EtheloApi.Helpers.ValidationHelper

  alias EtheloApi.Repo
  alias EtheloApi.Structure.Criteria
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure

  def valid_filters() do
    [:slug, :id, :decision_id, :deleted]
  end

  def match_query(decision_id, modifiers) do
    modifiers = Map.put(modifiers, :decision_id, decision_id)

    Criteria
    |> filter_query(modifiers, valid_filters())
  end

  defp maybe_update_hashes(record, decision, changes) do
    record
    |> Structure.maybe_update_structure_hash(decision, changes)
    |> Structure.maybe_update_decision_influent_hash(decision, changes)
  end

  @doc """
  Returns the list of Criterias for a Decision.

  ## Examples

      iex> list_criterias(decision_id)
      [%Criteria{}, ...]

  """
  def list_criterias(decision, modifiers \\ %{})

  def list_criterias(%Decision{} = decision, modifiers),
    do: list_criterias(decision.id, modifiers)

  def list_criterias(nil, _), do: raise(ArgumentError, message: "you must supply a Decision")

  def list_criterias(decision_id, modifiers) do
    decision_id |> match_query(modifiers) |> Repo.all()
  end

  @doc """
  Gets a single Criteria.

  returns nil if Criteria does not exist or does not belong to the specified Decision

  ## Examples

      iex> get_criteria(123, 1)
      %Criteria{}

      iex> get_criteria(456, 3)
      nil

  """
  def get_criteria(id, %Decision{} = decision), do: get_criteria(id, decision.id)
  def get_criteria(_, nil), do: raise(ArgumentError, message: "you must supply a Decision id")
  def get_criteria(nil, _), do: raise(ArgumentError, message: "you must supply a Criteria id")

  def get_criteria(id, decision_id) do
    Criteria |> Repo.get_by(id: id, decision_id: decision_id)
  end

  @doc """
  Creates a Criteria.

  ## Examples

      iex> create_criteria(decision, %{title: "This is my title"})
      {:ok, %Criteria{}}

      iex> create_criteria(decision, %{title: " "})
      {:error, %Ecto.Changeset{}}

  """
  def create_criteria(%{} = attrs, %Decision{} = decision) do
    EtheloApi.Structure.Queries.Decision.ensure_default_associations(decision)

    attrs
    |> Criteria.create_changeset(decision)
    |> Repo.insert()
    |> maybe_update_hashes(decision.id, %{new: true})
  end

  def create_criteria(_, _), do: raise(ArgumentError, message: "you must supply a Decision")

  @doc """
  Gets the first Criteria

  returns nil if no Criteria on the specified Decision

  ## Examples

      iex> first_criteria(1)
      %Criteria{}

      iex> first_criteria(3)
      nil

  """
  def first_criteria(decision_id) do
    Criteria
    |> where([t], t.decision_id == ^decision_id)
    |> limit(1)
    |> order_by(asc: :id)
    |> Repo.one()
  end

  @doc """
  Creates the default "approval" Criteria if no Criteria exist.
  This does not return a record.

  This method should only be used internally and should never be exposed via api

  ## Examples

      iex> ensure_one_criteria(decision)
      :ok

  """
  def ensure_one_criteria(%Decision{id: decision_id}) do
    first_criteria(decision_id)
    |> case do
      %Criteria{} = criteria -> {:ok, criteria}
      nil -> Repo.insert(%Criteria{decision_id: decision_id, title: "Approval", slug: "approval"})
    end
  end

  def ensure_one_criteria(_), do: raise(ArgumentError, message: "you must supply a Decision")

  @doc """
  Updates a Criteria.
  Note: this method will not change the Decision a Criteria belongs to.

  ## Examples

      iex> update_criteria(criteria, %{field: new_value})
      {:ok, %Criteria{}}

      iex> update_criteria(criteria, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_criteria(%Criteria{} = criteria, %{} = attrs) do
    changeset = criteria |> Criteria.update_changeset(attrs)

    changeset
    |> Repo.update()
    |> maybe_update_hashes(criteria.decision_id, changeset.changes)
  end

  @doc """
  Deletes a Criteria.

  ## Examples

      iex> delete_criteria(criteria, decision_id)
      {:ok, %Criteria{}, decision_id}

  """
  def delete_criteria(id, %Decision{} = decision), do: delete_criteria(id, decision.id)

  def delete_criteria(%Criteria{} = criteria, decision_id),
    do: delete_criteria(criteria.id, decision_id)

  def delete_criteria(_, nil), do: raise(ArgumentError, message: "you must supply a Decision id")
  def delete_criteria(nil, _), do: raise(ArgumentError, message: "you must supply a Criteria id")

  def delete_criteria(id, decision_id) do
    existing = get_criteria(id, decision_id)
    count = Repo.aggregate(Criteria, :count, :id)

    case {existing, count} do
      {nil, _} ->
        {:ok, nil}

      {_, 1} ->
        {:error, protected_record_changeset(Criteria, :id)}

      {existing, _} ->
        Repo.delete(existing)
        |> maybe_update_hashes(existing.decision_id, %{deleted: true})
    end
  end
end
