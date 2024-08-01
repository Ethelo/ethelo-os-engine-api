defmodule EtheloApi.Structure.Queries.Calculation do
  @moduledoc """
  Contains methods that will be delegated to inside structure.
  Used purely to reduce the size of structure.ex
  """

  import Ecto.Query, warn: false
  import EtheloApi.Helpers.EctoHelper

  alias EtheloApi.Repo
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Calculation
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.ExpressionParser

  def valid_filters() do
    [:slug, :id, :decision_id]
  end

  def match_query(decision_id, modifiers) do
    modifiers = Map.put(modifiers, :decision_id, decision_id)

    Calculation
    |> filter_query(modifiers, valid_filters())
  end

  @doc """
  Returns the list of Calculations for a Decision.

  ## Examples

      iex> list_calculations(decision_id)
      [%Calculation{}, ...]

  """
  def list_calculations(decision, modifiers \\ %{})

  def list_calculations(%Decision{} = decision, modifiers),
    do: list_calculations(decision.id, modifiers)

  def list_calculations(nil, _), do: raise(ArgumentError, message: "you must supply a Decision")

  def list_calculations(decision_id, modifiers) do
    decision_id |> match_query(modifiers) |> preload(:variables) |> Repo.all()
  end

  @doc """
  Gets a single Calculation.

  returns nil if Calculation does not exist or does not belong to the specified Decision

  ## Examples

      iex> get_calculation(123, 1)
      %Calculation{}

      iex> get_calculation(456, 3)
      nil

  """
  def get_calculation(id, %Decision{} = decision), do: get_calculation(id, decision.id)
  def get_calculation(_, nil), do: raise(ArgumentError, message: "you must supply a Decision id")

  def get_calculation(nil, _),
    do: raise(ArgumentError, message: "you must supply a Calculation id")

  def get_calculation(id, decision_id) do
    Calculation |> preload([:variables]) |> Repo.get_by(id: id, decision_id: decision_id)
  end

  @doc """
  Creates a  Calculation.

  ## Examples

      iex> create_calculation(decision, %{title: "This is my title"})
      {:ok, %Calculation{}}

      iex> create_calculation(decision, %{title: " "})
      {:error, %Ecto.Changeset{}}

  """
  def create_calculation(%{} = attrs, %Decision{} = decision) do
    attrs
    |> Calculation.create_changeset(decision)
    |> Repo.insert()
    |> Structure.maybe_update_structure_hash(decision, %{new: true})
  end

  def create_calculation(_, _), do: raise(ArgumentError, message: "you must supply a Decision")

  @doc """
  Updates a Calculation.
  Note: this method will not change the Decision a Calculation belongs to.

  ## Examples

      iex> update_calculation(calculation, %{field: new_value})
      {:ok, %Calculation{}}

      iex> update_calculation(calculation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_calculation(%Calculation{} = calculation, %{} = attrs) do
    changeset = calculation |> Calculation.update_changeset(attrs)

    changeset
    |> Repo.update()
    |> Structure.maybe_update_structure_hash(calculation.decision_id, changeset.changes)
  end

  def replace_variable_in_calculation(calculation, old, new) do
    parsed = ExpressionParser.parse(calculation.expression)

    expression =
      " #{parsed.parsed} "
      |> String.replace(~r/ #{old} /, " #{new} ")

    calculation
    |> Calculation.update_changeset(%{expression: expression})
    |> Repo.update()
  end

  @doc """
  Deletes a Calculation.

  ## Examples

      iex> delete_calculation(calculation, decision_id)
      {:ok, %Calculation{}, decision_id}

  """
  def delete_calculation(id, %Decision{} = decision), do: delete_calculation(id, decision.id)

  def delete_calculation(%Calculation{} = calculation, decision_id),
    do: delete_calculation(calculation.id, decision_id)

  def delete_calculation(_, nil),
    do: raise(ArgumentError, message: "you must supply a Decision id")

  def delete_calculation(nil, _),
    do: raise(ArgumentError, message: "you must supply a Calculation id")

  def delete_calculation(id, decision_id) do
    id
    |> get_calculation(decision_id)
    |> case do
      nil ->
        {:ok, nil}

      calculation ->
        Repo.delete(calculation)
        |> Structure.maybe_update_structure_hash(decision_id, %{deleted: true})
    end
  end
end
