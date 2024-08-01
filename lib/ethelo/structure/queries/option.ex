defmodule EtheloApi.Structure.Queries.Option do
  @moduledoc """
  Contains methods that will be delegated to inside structure.
  Used purely to reduce the size of structure.ex
  """

  import Ecto.Query, warn: false
  alias EtheloApi.Repo
  import EtheloApi.Helpers.QueryHelper

  alias EtheloApi.Structure
  alias EtheloApi.Structure.Option
  alias EtheloApi.Structure.Decision

  def valid_filters() do
    [:slug, :id, :option_category_id, :enabled, :decision_id, :deleted]
  end

  @doc """
  private method to start querying with acceptable preloads
  """
  def base_query() do
    Option |> preload([:option_detail_values, :option_category])
  end

  def match_query(decision_id, filters) do
    filters = Map.put(filters, :decision_id, decision_id)

    Option
    |> preload([:option_detail_values, :option_category])
    |> filter_query(filters, valid_filters())
  end

  def filter_by_option_filter(nil, _, _), do: []
  def filter_by_option_filter([], _, _), do: []
  def filter_by_option_filter(option_list, decision_id, %{option_filter_id: option_filter_id}) do
    case Structure.get_option_filter(option_filter_id, decision_id) do
      nil -> [] # nonexistent filter matches nothing
      option_filter ->
        matching = Structure.option_ids_matching_filter(option_filter, true)
        option_list |> Enum.filter(fn(option) -> option.id in matching end)
    end
  end
  def filter_by_option_filter(option_list, _, _), do: option_list

  defp maybe_update_hashes(record, decision, changes) do
    record
    |> Structure.maybe_update_structure_hash(decision, changes)
    |> Structure.maybe_update_decision_weighting_hash(decision, changes)
    |> Structure.maybe_update_decision_influent_hash(decision, changes)
  end

  @doc """
  Returns the list of Option records for a Decision.
  Optionally filter by field, or return a subset of fields instead of an object

  ## Examples

      iex> list_options(decision_id)
      [%Option{}, ...]

      iex> list_options(decision_id, %{enabled: "true"})
      [%Option{}, ...]

      iex> list_options(decision_id, %{}, [:id])
      [%{id: _}, ...]

  """
  def list_options(decision, filters \\ %{}, fields \\ nil)
  def list_options(%Decision{} = decision, filters, fields) do
     list_options(decision.id, filters, fields)
  end
  def list_options(nil, _, _), do: raise ArgumentError, message: "you must supply a Decision"
  def list_options(decision_id, filters, fields) do
      decision_id
      |> match_query(filters)
      |> only_fields(fields)
      |> only_distinct(filters)
      |> Repo.all
      |> filter_by_option_filter(decision_id, filters)
  end

  @doc """
  Returns the list of matchng Options for a Decision.
  Used for batch processing

  ## Examples

      iex> match_options(decision_id)
      [%Option{}, ...]

  """
  def match_options(filters \\ %{}, decision_ids)
  def match_options(filters, decision_ids) when is_list(decision_ids) do
    decision_ids = Enum.uniq(decision_ids)

    Option
    |> preload(:option_detail_values)
    |> where([t], t.decision_id in ^decision_ids)
    |> filter_query(filters, valid_filters())
    |> Repo.all
  end
  def match_options(_, nil), do: raise ArgumentError, message: "you must supply a list of Decision ids"

  @doc """
  Returns the list of Options matching the supplied ids.

  ## Examples

      iex> list_options_by_ids([1, 2], decision_id)
      [%Option{}, ...]

  """
  def list_options_by_ids(option_ids, %Decision{} = decision), do: list_options_by_ids(option_ids, decision.id)
  def list_options_by_ids(_, nil), do: raise ArgumentError, message: "you must supply a Decision"
  def list_options_by_ids([], _), do: []
  def list_options_by_ids(nil, _), do: []
  def list_options_by_ids(option_ids, decision_id) do
    option_ids = Enum.uniq(option_ids)

    base_query()
    |> where([t], t.decision_id == ^decision_id)
    |> where([t], t.id in ^option_ids)
    |> Repo.all
  end

  @doc """
  Gets a single option.

  returns nil if Option does not exist or does not belong to the specified Decision

  ## Examples

      iex> get_option(123, 1)
      %Option{}

      iex> get_option(456, 3)
      nil

  """
  def get_option(id, %Decision{} = decision), do: get_option(id, decision.id)
  def get_option(_, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def get_option(nil, _), do:  raise ArgumentError, message: "you must supply an Option id"
  def get_option(id, decision_id) do
    base_query() |> Repo.get_by(id: id, decision_id: decision_id)
  end

  @doc """
  Creates an option.

  ## Examples

      iex> create_option(decision, %{title: "This is my title"})
      {:ok, %Option{}}

      iex> create_option(decision, %{title: " "})
      {:error, %Ecto.Changeset{}}

  """
  def create_option(%Decision{} = decision, %{} = attrs) do
    EtheloApi.Structure.Queries.Decision.ensure_default_associations(decision)

    %Option{}
    |> Option.create_changeset(attrs, decision)
    |> Repo.insert()
    |> maybe_update_hashes(decision.id, %{new: true})
  end
  def create_option(_, _), do: raise ArgumentError, message: "you must supply a Decision"

  @doc """
  Updates an option.
  Note: this method will not change the Decision an Option belongs to.

  ## Examples

      iex> update_option(option, %{field: new_value})
      {:ok, %Option{}}

      iex> update_option(option, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_option(%Option{} = option, %{} = attrs) do
    changeset = option |> Option.update_changeset(attrs)
    changeset
    |> Repo.update()
    |> maybe_update_hashes(option.decision_id, changeset.changes)
  end

  @doc """
  Deletes a Option.

  ## Examples

      iex> delete_option(option, decision_id)
      {:ok, %Option{}, decision_id}

  """
  def delete_option(id, %Decision{} = decision), do: delete_option(id, decision.id)
  def delete_option(%Option{} = option, decision_id), do: delete_option(option.id, decision_id)
  def delete_option(_, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def delete_option(nil, _), do:  raise ArgumentError, message: "you must supply an Option id"
  def delete_option(id, decision_id) do
    id
    |> get_option(decision_id)
    |> case do
      nil -> {:ok, nil}
      option ->
        Repo.delete(option)
        |> maybe_update_hashes(decision_id, %{deleted: true})

    end
  end
end
