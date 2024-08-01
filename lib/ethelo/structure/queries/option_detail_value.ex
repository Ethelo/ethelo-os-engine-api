defmodule EtheloApi.Structure.Queries.OptionDetailValue do
  @moduledoc """
  Contains methods that will be delegated to inside structure.
  Used purely to reduce the size of structure.ex
  """

  import Ecto.Query, warn: false
  alias EtheloApi.Repo
  import EtheloApi.Helpers.QueryHelper

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Option
  alias EtheloApi.Structure.OptionDetail
  alias EtheloApi.Structure.OptionDetailValue
  alias EtheloApi.Structure.Decision

  def valid_filters() do
    [:decision_id, :option_id, :option_detail_id]
  end

  @doc """
  private method to start querying with acceptable preloads
  """
  def base_query() do
    OptionDetailValue |> order_by(asc: :option_id, asc: :option_detail_id)
  end

  def match_query(decision_id, filters) do
    filters = Map.put(filters, :decision_id, decision_id)

    OptionDetailValue
    |> order_by(:value)
    |> filter_query(filters, valid_filters())
  end

  @doc """
  Returns the list of OptionDetailValues for a Decision.
  Optionally filter by field, or return a subset of fields instead of an object

  ## Examples

      iex> list_option_detail_values(decision_id)
      [%OptionDetailValue{}, ...]

  """
  def list_option_detail_values(decision, filters \\ %{}, fields \\ nil)
  def list_option_detail_values(%Decision{} = decision, filters, fields) do
     list_option_detail_values(decision.id, filters, fields)
  end
  def list_option_detail_values(nil, _, _), do: raise ArgumentError, message: "you must supply a Decision"
  def list_option_detail_values(decision_id, filters, fields) do
    decision_id
      |> match_query(filters)
      |> only_fields(fields)
      |> only_distinct(filters)
      |> Repo.all
  end

  @doc """
  Returns the list of OptionDetailValues for a Decision.

  ## Examples

      iex> list_option_detail_values(decision_id)
      [%OptionDetailValue{}, ...]

  """
  def match_option_detail_values(filters \\ %{}, decision_ids)
  def match_option_detail_values(filters, decision_ids) when is_list(decision_ids) do
    decision_ids = Enum.uniq(decision_ids)

    OptionDetailValue
    |> where([t], t.decision_id in ^decision_ids)
    |> filter_query(filters, valid_filters())
    |> Repo.all
  end
  def match_option_detail_values(_, nil), do: raise ArgumentError, message: "you must supply a list of Decision ids"


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
  def get_option_detail_value(_, _, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def get_option_detail_value(option_id, %OptionDetail{} = option_detail, decision_id) do
     get_option_detail_value(option_id, option_detail.id, decision_id)
  end
  def get_option_detail_value(_, nil, _), do: raise ArgumentError, message: "you must supply an OptionDetail id"
  def get_option_detail_value(%Option{} = option, option_detail_id, decision_id) do
     get_option_detail_value(option.id, option_detail_id, decision_id)
  end
  def get_option_detail_value(nil, _, _), do: raise ArgumentError, message: "you must supply an Option id"
  def get_option_detail_value(option_id, option_detail_id, decision_id) do
    OptionDetailValue |> Repo.get_by(option_id: option_id, option_detail_id: option_detail_id, decision_id: decision_id)
  end
  def get_option_detail_value(%{option_id: option_id, option_detail_id: option_detail_id}, %Decision{} = decision) do
     get_option_detail_value(option_id, option_detail_id, decision.id)
  end
  def get_option_detail_value(%{option_id: option_id, option_detail_id: option_detail_id}, decision_id) do
     get_option_detail_value(option_id, option_detail_id, decision_id)
  end

  @doc """
  Creates or Updates an OptionDetailValue.

  ## Examples

      iex> upsert_option_detail_value(decision, %{title: "This is my title"})
      {:ok, %OptionDetailValue{}}

      iex> upsert_option_detail_value(decision, %{title: " "})
      {:error, %Ecto.Changeset{}}

  """
  def upsert_option_detail_value(%Decision{} = decision, %{} = attrs) do
    changeset = %OptionDetailValue{} |> OptionDetailValue.create_changeset(attrs, decision)
    on_conflict = [set: [value: Ecto.Changeset.get_field(changeset, :value)]]
    conflict_target = [:option_id, :option_detail_id]
    Repo.insert(changeset, on_conflict: on_conflict, conflict_target: conflict_target)
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
      nil -> {:ok, nil}
      option_detail_value ->
        Repo.delete(option_detail_value)
        |> Structure.maybe_update_structure_hash(decision_id, %{deleted: true})

    end
  end

end
