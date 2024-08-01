defmodule EtheloApi.Structure.Queries.OptionFilter do
  @moduledoc """
  Contains methods that will be delegated to inside structure.
  Used purely to reduce the size of structure.ex
  """

  import Ecto.Query, warn: false
  import EtheloApi.Helpers.ValidationHelper
  import EtheloApi.Helpers.EctoHelper

  alias EtheloApi.Repo
  alias EtheloApi.Structure
  alias EtheloApi.Structure.OptionFilter
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.FilterOptions

  def valid_filters() do
    [:slug, :id, :option_category_id, :option_detail_id, :decision_id]
  end

  def match_query(decision_id, modifiers) do
    modifiers = Map.put(modifiers, :decision_id, decision_id)

    OptionFilter
    |> preload([:option_detail, :option_category])
    |> filter_query(modifiers, valid_filters())
  end

  @doc """
  Returns the list of OptionFilters for a Decision.

  ## Examples

      iex> list_option_filters(decision_id)
      [%OptionFilter{}, ...]

  """
  def list_option_filters(decision, modifiers \\ %{})

  def list_option_filters(%Decision{} = decision, modifiers),
    do: list_option_filters(decision.id, modifiers)

  def list_option_filters(nil, _), do: raise(ArgumentError, message: "you must supply a Decision")

  def list_option_filters(decision_id, modifiers) do
    decision_id |> match_query(modifiers) |> Repo.all()
  end

  @doc """
  Gets a single OptionFilter.

  returns nil if OptionFilter does not exist or does not belong to the specified Decision

  ## Examples

      iex> get_option_filter(123, 1)
      %OptionFilter{}

      iex> get_option_filter(456, 3)
      nil

  """
  def get_option_filter(id, %Decision{} = decision), do: get_option_filter(id, decision.id)

  def get_option_filter(_, nil),
    do: raise(ArgumentError, message: "you must supply a Decision id")

  def get_option_filter(nil, _),
    do: raise(ArgumentError, message: "you must supply an OptionFilter id")

  def get_option_filter(id, decision_id) do
    OptionFilter |> Repo.get_by(id: id, decision_id: decision_id)
  end

  @doc """
  Creates an OptionFilter.

  ## Examples

      iex> create_option_filter(decision, %{title: "This is my title"})
      {:ok, %OptionFilter{}}

      iex> create_option_filter(decision, %{title: " "})
      {:error, %Ecto.Changeset{}}

  """
  def create_option_filter(attrs, decision, post_process \\ true)

  def create_option_filter(%{} = attrs, %Decision{} = decision, post_process) do
    EtheloApi.Structure.Queries.Decision.ensure_default_associations(decision)

    result =
      attrs
      |> OptionFilter.create_changeset(decision)
      |> Repo.insert()

    if post_process do
      Structure.ensure_filters_and_vars(result, decision, %{new: true})
      Structure.maybe_update_structure_hash(result, decision, %{new: true})
    end

    result
  end

  def create_option_filter(_, _, _),
    do: raise(ArgumentError, message: "you must supply a Decision")

  @doc """
  Creates the default "All Options" OptionFilter if it does not exist.
  This does not return a record.

  This method should only be used internally and should never be exposed via api

  ## Examples

      iex> ensure_all_options_filter(decision)
      :ok

  """
  def ensure_all_options_filter(%Decision{id: decision_id} = decision) do
    # upsert manually as Ecto 2.1.4 does not support partial index upserts
    # this could have race conditions leading to failure, this is acceptable
    # as in that case an "AllOptions" OptionFilter would still be present

    all_options = OptionFilter.all_options_mode()

    OptionFilter
    |> where([t], t.match_mode == ^all_options)
    |> where([t], t.decision_id == ^decision_id)
    |> Repo.one()
    |> case do
      %OptionFilter{} -> :ok
      _ -> insert_all_options_filter(decision)
    end
  end

  def ensure_all_options_filter(_),
    do: raise(ArgumentError, message: "you must supply a Decision")

  defp insert_all_options_filter(decision) do
    decision
    |> OptionFilter.all_options_changeset()
    |> Repo.insert()

    :ok
  end

  @doc """
  Updates an OptionFilter.
  Note: this method will not change the Decision an OptionFilter belongs to.
  "All Options" OptionFilter cannot be updated

  ## Examples

      iex> update_option_filter(option_filter, %{field: new_value})
      {:ok, %OptionFilter{}}

      iex> update_option_filter(option_filter, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_option_filter(option_filter, attrs, post_process \\ true)

  def update_option_filter(option_filter, attrs, post_process) when attrs == %{} do
    {:ok, option_filter} |> update_post_process(post_process, attrs)
  end

  def update_option_filter(%OptionFilter{} = option_filter, %{} = attrs, post_process) do
    changeset = option_filter |> OptionFilter.update_changeset(attrs)

    changeset
    |> Repo.update()
    |> update_post_process(post_process, changeset.changes)
  end

  defp update_post_process(result, post_process, changes)

  defp update_post_process({:ok, option_filter} = result, true, changes) do
    Structure.ensure_filters_and_vars(result, option_filter.decision_id, changes)
    Structure.maybe_update_structure_hash(result, option_filter.decision_id, changes)
  end

  defp update_post_process(result, _, _), do: result

  @doc """
  Deletes an OptionFilter.
  "All Options" OptionFilter cannot be deleted

  ## Examples

      iex> delete_option_filter(option_filter, decision_id)
      {:ok, %OptionFilter{}, decision_id}

  """
  @all_options_mode OptionFilter.all_options_mode()
  def delete_option_filter(id, %Decision{} = decision), do: delete_option_filter(id, decision.id)

  def delete_option_filter(%OptionFilter{} = option_filter, decision_id),
    do: delete_option_filter(option_filter.id, decision_id)

  def delete_option_filter(_, nil),
    do: raise(ArgumentError, message: "you must supply a Decision id")

  def delete_option_filter(nil, _),
    do: raise(ArgumentError, message: "you must supply an OptionFilter id")

  def delete_option_filter(id, decision_id) do
    id
    |> get_option_filter(decision_id)
    |> case do
      %OptionFilter{match_mode: @all_options_mode} ->
        {:error, protected_record_changeset(OptionFilter, :id)}

      nil ->
        {:ok, nil}

      option_filter ->
        Repo.delete(option_filter)
        |> Structure.maybe_update_structure_hash(decision_id, %{deleted: true})
    end
  end

  @doc """
  Returns the list of Options that pass all submitted OptionFilters for one decision.
  Use for batch loading in graphql
  returns both excluded and included options

  ## Examples

      iex> options_by_filter_ids(decision_id, option_filter_ids)
      %{1: [%Option{}, ...], 2: [..]}

  """
  def options_by_filter_ids(decision_id, filter_ids)
      when is_integer(decision_id) and is_list(filter_ids) do
    %{ids: ids} = option_ids_by_filter_ids(decision_id, filter_ids)

    options = Structure.list_options(decision_id)

    ids
    |> Enum.map(fn {option_filter_id, option_ids} ->
      matched =
        options
        |> Enum.filter(fn option -> option.id in option_ids end)
        |> Enum.sort_by(& &1.id)

      {option_filter_id, matched}
    end)
    |> Enum.into(%{})
  end

  def options_by_filter_ids(_decision_ids, filter_ids) when is_list(filter_ids),
    do: raise(ArgumentError, message: "you must supply a Decision id")

  def options_by_filter_ids(decision_id, _filter_ids) when is_integer(decision_id),
    do: raise(ArgumentError, message: "you must supply a list of OptionFilter ids")

  def options_by_filter_ids(_decision_ids, _filter_ids),
    do:
      raise(ArgumentError, message: "you must supply a Decision id and list of OptionFilter ids")

  @doc """
  Returns the list of Options that pass all submitted OptionFilters for one decision.
  Use for batch loading in graphql
  returns both excluded and included options

  ## Examples

      iex> option_ids_by_filter_ids(decision_id, option_filter_ids)
      %{1: [23,43], 2: [..]}

  """
  def option_ids_by_filter_ids(decision_id, filter_ids)
      when is_integer(decision_id) and is_list(filter_ids) do
    OptionFilter
    |> where([t], t.decision_id == ^decision_id)
    |> where([t], t.id in ^filter_ids)
    |> Repo.all()
    |> FilterOptions.option_ids_matching_filters(decision_id, false)
  end

  def option_ids_by_filter_ids(_decision_ids, filter_ids) when is_list(filter_ids),
    do: raise(ArgumentError, message: "you must supply a Decision id")

  def option_ids_by_filter_ids(decision_id, _filter_ids) when is_integer(decision_id),
    do: raise(ArgumentError, message: "you must supply a list of OptionFilter ids")

  def option_ids_by_filters(_decision_ids, _filter_ids),
    do:
      raise(ArgumentError, message: "you must supply a Decision id and list of OptionFilter ids")
end
