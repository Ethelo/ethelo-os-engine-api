defmodule EtheloApi.Structure.Queries.OptionFilter do
  @moduledoc """
  Contains methods that will be delegated to inside structure.
  Used purely to reduce the size of structure.ex
  """

  import Ecto.Query, warn: false
  import EtheloApi.Helpers.ValidationHelper
  import EtheloApi.Helpers.QueryHelper

  alias EtheloApi.Repo
  alias EtheloApi.Structure
  alias EtheloApi.Structure.OptionFilter
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Constraints.FilterOptions

  def valid_filters() do
    [:slug, :id, :option_category_id, :option_detail_id, :decision_id]
  end

  @doc """
  private method to start querying with acceptable preloads
  """
  def base_query() do
    OptionFilter
  end

  def match_query(decision_id, filters) do
    filters = Map.put(filters, :decision_id, decision_id)

    OptionFilter
    |> preload([:option_detail, :option_category])
    |> filter_query(filters, valid_filters())
  end

  @doc """
  Returns the list of OptionFilters for a Decision.

  ## Examples

      iex> list_option_filters(decision_id)
      [%OptionFilter{}, ...]

  """
  def list_option_filters(decision, filters \\ %{})
  def list_option_filters(%Decision{} = decision, filters), do: list_option_filters(decision.id, filters)
  def list_option_filters(nil, _), do: raise ArgumentError, message: "you must supply a Decision"
  def list_option_filters(decision_id, filters) do
    decision_id |> match_query(filters) |> Repo.all
  end

  @doc """
  Returns a list of matching OptionFilters for a list of Decision ids.

  ## Examples

      iex> match_option_filters(decision_id)
      [%OptionFilter{}, ...]

  """
  def match_option_filters(filters \\ %{}, decision_ids)
  def match_option_filters(filters, decision_ids) when is_list(decision_ids) do
    decision_ids = Enum.uniq(decision_ids)

    OptionFilter
    |> where([t], t.decision_id in ^decision_ids)
    |> filter_query(filters, valid_filters())
    |> Repo.all
  end
  def match_option_filters(_, nil), do: raise ArgumentError, message: "you must supply a list of Decision ids"


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
  def get_option_filter(_, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def get_option_filter(nil, _), do:  raise ArgumentError, message: "you must supply an OptionFilter id"
  def get_option_filter(id, decision_id) do
    base_query() |> Repo.get_by(id: id, decision_id: decision_id)
  end

  @doc """
  Creates an option_filter.

  ## Examples

      iex> create_option_filter(decision, %{title: "This is my title"})
      {:ok, %OptionFilter{}}

      iex> create_option_filter(decision, %{title: " "})
      {:error, %Ecto.Changeset{}}

  """
  def create_option_filter(decision, attrs, post_process \\ true)
  def create_option_filter(%Decision{} = decision, %{} = attrs, post_process) do
    EtheloApi.Structure.Queries.Decision.ensure_default_associations(decision)

    result = %OptionFilter{}
    |> OptionFilter.create_changeset(attrs, decision)
    |> Repo.insert()

    if post_process do
      Structure.ensure_filters_and_vars(result, decision, %{new: true})
      Structure.maybe_update_structure_hash(result, decision, %{new: true})
     end

    result
  end
  def create_option_filter(_, _, _), do: raise ArgumentError, message: "you must supply a Decision"

  @doc """
  Creates the default "all options" OptionFilter if it does not exist.
  This does not return a record.

  This method should only be used internally and should never be exposed via api

  ## Examples

      iex> ensure_all_options_filter(decision)
      :ok

  """
  def ensure_all_options_filter(%Decision{id: decision_id} = decision) do
    #upsert manually as Ecto 2.1.4 does not support partial index upserts
    #this could have race conditions leading to failure, this is acceptable
    #as in that case a all options filter would still be present

    all_options = OptionFilter.all_options_mode()

    OptionFilter
    |> where([t], t.match_mode == ^all_options)
    |> where([t], t.decision_id == ^decision_id)
    |> Repo.one
    |> case do
      %OptionFilter{} -> :ok
      _ -> insert_all_options_filter(decision)
    end
  end
  def ensure_all_options_filter(_), do: raise ArgumentError, message: "you must supply a Decision"

  defp insert_all_options_filter(decision) do
    decision
    |> OptionFilter.all_options_changeset()
    |> Repo.insert()
    :ok
  end

  @doc """
  Updates an OptionFilter.
  Note: this method will not change the Decision an OptionFilter belongs to.
  "all options" filter cannot be updated

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
  Deletes a OptionFilter.
  "all options" filter cannot be deleted

  ## Examples

      iex> delete_option_filter(option_filter, decision_id)
      {:ok, %OptionFilter{}, decision_id}

  """
  @all_options_mode OptionFilter.all_options_mode()
  def delete_option_filter(id, %Decision{} = decision), do: delete_option_filter(id, decision.id)
  def delete_option_filter(%OptionFilter{} = option_filter, decision_id), do: delete_option_filter(option_filter.id, decision_id)
  def delete_option_filter(_, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def delete_option_filter(nil, _), do:  raise ArgumentError, message: "you must supply an OptionFilter id"
  def delete_option_filter(id, decision_id) do
    id
    |> get_option_filter(decision_id)
    |> case do
      %OptionFilter{match_mode: @all_options_mode} -> {:error, protected_record_changeset(OptionFilter, :id)}
      nil -> {:ok, nil}
      option_filter ->
        Repo.delete(option_filter)
        |> Structure.maybe_update_structure_hash(decision_id, %{deleted: true})

    end
  end

  @doc """
  Returns the list of options that pass all filters. Use for batch loading in graphql
  returns both excluded and included options

  ## Examples

      iex> all_options_for_all_filters(decision_ids)
      [%Option{}, ...]

  """
  def all_options_for_all_filters(decision_ids) when is_list(decision_ids) do
    options = Structure.match_options(%{}, decision_ids)

    %{ids: ids} = %{}
    |> match_option_filters(decision_ids)
    |> FilterOptions.option_ids_matching_filters(false)

    ids |> Enum.map(fn {option_filter_id, option_ids} ->
       matched = Enum.filter(options, fn(option) -> option.id in option_ids end)
       {option_filter_id, matched}
    end)
    |> Enum.into(%{})
  end
  def all_options_for_all_filters(_), do: raise ArgumentError, message: "you must supply a list of Decision ids"

  # when used by graphql, an empty second argument is sent
  def all_options_for_all_filters(_, decision_ids), do: all_options_for_all_filters(decision_ids)

end
