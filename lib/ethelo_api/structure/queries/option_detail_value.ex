defmodule EtheloApi.Structure.Queries.OptionDetailValue do
  @moduledoc """
  Contains methods that will be delegated to inside structure.
  Used purely to reduce the size of structure.ex
  """

  import Ecto.Query, warn: false
  alias EtheloApi.Repo
  import EtheloApi.Helpers.EctoHelper

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Option
  alias EtheloApi.Structure.OptionDetail
  alias EtheloApi.Structure.OptionDetailValue
  alias EtheloApi.Structure.Decision

  def valid_filters() do
    [:decision_id, :option_id, :option_detail_id]
  end

  def match_query(decision_id, modifiers) do
    modifiers = Map.put(modifiers, :decision_id, decision_id)

    OptionDetailValue
    |> order_by(:value)
    |> filter_query(modifiers, valid_filters())
  end

  @doc """
  Returns the list of OptionDetailValues for a Decision.
  Optionally filter by field, or return a subset of fields instead of an object

  ## Examples

      iex> list_option_detail_values(decision_id)
      [%OptionDetailValue{}, ...]

  """
  def list_option_detail_values(decision, modifiers \\ %{}, fields \\ nil)

  def list_option_detail_values(%Decision{} = decision, modifiers, fields) do
    list_option_detail_values(decision.id, modifiers, fields)
  end

  def list_option_detail_values(nil, _, _),
    do: raise(ArgumentError, message: "you must supply a Decision")

  def list_option_detail_values(decision_id, modifiers, fields) do
    decision_id
    |> match_query(modifiers)
    |> only_fields(fields)
    |> only_distinct(modifiers)
    |> Repo.all()
  end

  @doc """
  Gets a single OptionDetailValue.

  returns nil if OptionDetailValue does not exist or does not belong to the specified Decision

  ## Examples

      iex> get_option_detail_value(123, 1)
      %OptionDetailValue{}

      iex> get_option_detail_value(456, 3)
      nil

  """
  def get_option_detail_value(option_id, option_detail_id, %Decision{} = decision) do
    get_option_detail_value(option_id, option_detail_id, decision.id)
  end

  def get_option_detail_value(_, _, nil),
    do: raise(ArgumentError, message: "you must supply a Decision id")

  def get_option_detail_value(option_id, %OptionDetail{} = option_detail, decision_id) do
    get_option_detail_value(option_id, option_detail.id, decision_id)
  end

  def get_option_detail_value(_, nil, _),
    do: raise(ArgumentError, message: "you must supply an OptionDetail id")

  def get_option_detail_value(%Option{} = option, option_detail_id, decision_id) do
    get_option_detail_value(option.id, option_detail_id, decision_id)
  end

  def get_option_detail_value(nil, _, _),
    do: raise(ArgumentError, message: "you must supply an Option id")

  def get_option_detail_value(option_id, option_detail_id, decision_id) do
    OptionDetailValue
    |> Repo.get_by(
      option_id: option_id,
      option_detail_id: option_detail_id,
      decision_id: decision_id
    )
  end

  def get_option_detail_value(
        %{option_id: option_id, option_detail_id: option_detail_id},
        %Decision{} = decision
      ) do
    get_option_detail_value(option_id, option_detail_id, decision.id)
  end

  def get_option_detail_value(
        %{option_id: option_id, option_detail_id: option_detail_id},
        decision_id
      ) do
    get_option_detail_value(option_id, option_detail_id, decision_id)
  end

  @doc """
  Creates or Updates an OptionDetailValue.

  ## Examples

      iex> upsert_option_detail_value( %{title: "This is my title"}, decision)
      {:ok, %OptionDetailValue{}}

      iex> upsert_option_detail_value( %{title: " "}, decision)
      {:error, %Ecto.Changeset{}}

  """
  def upsert_option_detail_value(%{} = attrs, %Decision{} = decision) do
    attrs
    |> OptionDetailValue.upsert_changeset(decision)
    |> Repo.insert(
      on_conflict: {:replace, [:value, :updated_at]},
      conflict_target: [:option_id, :option_detail_id],
      returning: true
    )
    |> Structure.maybe_update_structure_hash(decision, %{updated: true})
  end

  @doc """
  Deletes a OptionDetailValue.

  ## Examples

      iex> delete_option_detail_value(option, decision_id)
      {:ok, %OptionDetailValue{}, decision_id}

  """
  def delete_option_detail_value(option_detail_value, decision_id) do
    option_detail_value = get_option_detail_value(option_detail_value, decision_id)

    case option_detail_value do
      nil ->
        {:ok, nil}

      option_detail_value ->
        Repo.delete(option_detail_value)
        |> Structure.maybe_update_structure_hash(decision_id, %{deleted: true})
    end
  end
end
