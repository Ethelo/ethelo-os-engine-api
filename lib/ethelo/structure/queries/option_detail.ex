defmodule EtheloApi.Structure.Queries.OptionDetail do
  @moduledoc """
  Contains methods that will be delegated to inside structure.
  Used purely to reduce the size of structure.ex
  """

  import Ecto.Query, warn: false
  import EtheloApi.Helpers.QueryHelper
  alias EtheloApi.Repo
  alias EtheloApi.Structure
  alias EtheloApi.Structure.OptionDetail
  alias EtheloApi.Structure.Decision

  def valid_filters() do
    [:slug, :id, :decision_id, :format]
  end

  @doc """
  private method to start querying with acceptable preloads
  """
  def base_query() do
    OptionDetail |> preload([:decision])
  end

  def match_query(decision_id, filters) do
    filters = Map.put(filters, :decision_id, decision_id)

    OptionDetail
    |> filter_query(filters, valid_filters())
  end

  @doc """
  Returns the list of OptionDetail records for a Decision.
  Optionally filter by field, or return a subset of fields instead of an object

  ## Examples

      iex> list_option_details(decision_id)
      [%OptionDetail{}, ...]

      iex> list_option_details(decision_id, %{slug: "sample"})
      [%OptionDetail{}]

      iex> list_option_details(decision_id, %{}, [:id])
      [%{id: _}, ...]

  """
  def list_option_details(decision, filters \\ %{}, fields \\ nil)
  def list_option_details(%Decision{} = decision, filters, fields) do
     list_option_details(decision.id, filters, fields)
  end
  def list_option_details(nil, _, _), do: raise ArgumentError, message: "you must supply a Decision"
  def list_option_details(decision_id, filters, fields) do
    decision_id |> match_query(filters)
      |> only_fields(fields)
      |> only_distinct(filters)
      |> Repo.all
  end


  @doc """
  Returns the list of OptionDetails for a list of Decision ids.

  ## Examples

      iex> match_option_details(decision_id)
      [%Option{}, ...]

  """
  def match_option_details(filters \\ %{}, decision_ids)
  def match_option_details(filters, decision_ids) when is_list(decision_ids) do
    decision_ids = Enum.uniq(decision_ids)

    OptionDetail
    |> where([t], t.decision_id in ^decision_ids)
    |> filter_query(filters, valid_filters())
    |> Repo.all
  end
  def match_option_details(_, nil), do: raise ArgumentError, message: "you must supply a list of Decision ids"

  @doc """
  Gets a single OptionDetail.

  returns nil if OptionDetail does not exist or does not belong to the specified Decision

  ## Examples

      iex> get_option_detail(123, 1)
      %OptionDetail{}

      iex> get_option_detail(456, 3)
      nil

  """
  def get_option_detail(id, %Decision{} = decision), do: get_option_detail(id, decision.id)
  def get_option_detail(_, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def get_option_detail(nil, _), do:  raise ArgumentError, message: "you must supply an OptionDetail id"
  def get_option_detail(id, decision_id) do
    base_query()
    |> Repo.get_by(id: id, decision_id: decision_id)
  end

  @doc """
  Creates an OptionDetail.

  ## Examples

      iex> create_option_detail(decision, %{title: "This is my title"})
      {:ok, %OptionDetail{}}

      iex> create_option_detail(decision, %{title: " "})
      {:error, %Ecto.Changeset{}}

  """
  def create_option_detail(decision, attrs, post_process \\ true)
  def create_option_detail(%Decision{} = decision, %{} = attrs, post_process) do
    result = %OptionDetail{}
    |> OptionDetail.create_changeset(attrs, decision)
    |> Repo.insert()

    if post_process do
      Structure.ensure_filters_and_vars(result, decision, %{new: true})
      Structure.maybe_update_structure_hash(result, decision, %{new: true})
    end

    result
  end
  def create_option_detail(_, _, _), do: raise ArgumentError, message: "you must supply a Decision"

  @doc """
  Updates an OptionDetail.
  Note: this method will not change the Decision an OptionDetail belongs to.

  ## Examples

      iex> update_option_detail(option_detail, %{field: new_value})
      {:ok, %OptionDetail{}}

      iex> update_option_detail(option_detail, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_option_detail(%OptionDetail{} = option_detail, %{} = attrs, post_process \\ true) do
    changeset = option_detail |> OptionDetail.update_changeset(attrs)
    result =  changeset |> Repo.update()

    if post_process do
      Structure.ensure_filters_and_vars(result, option_detail.decision_id, changeset.changes)
      Structure.maybe_update_structure_hash(result, option_detail.decision_id, changeset.changes)
    end

    result
  end

  @doc """
  Deletes an OptionDetail.

  ## Examples

      iex> delete_option_detail(option_detail, decision_id)
      {:ok, %OptionDetail{}, decision_id}

  """
  def delete_option_detail(id, %Decision{} = decision), do: delete_option_detail(id, decision.id)
  def delete_option_detail(%OptionDetail{} = option_detail, decision_id), do: delete_option_detail(option_detail.id, decision_id)
  def delete_option_detail(_, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def delete_option_detail(nil, _), do:  raise ArgumentError, message: "you must supply an OptionDetail id"
  def delete_option_detail(id, decision_id) do
    id
    |> get_option_detail(decision_id)
    |> case do
      nil -> {:ok, nil}
      option_detail ->
        Repo.delete(option_detail)
        |> Structure.maybe_update_structure_hash(decision_id, %{deleted: true})
    end
  end


end
