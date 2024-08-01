defmodule EtheloApi.Structure.Queries.OptionCategory do
  @moduledoc """
  Contains methods that will be delegated to inside structure.
  Used purely to reduce the size of structure.ex
  """

  import Ecto.Query, warn: false
  alias EtheloApi.Repo
  alias EtheloApi.Structure
  alias EtheloApi.Structure.OptionCategory
  alias EtheloApi.Structure.Decision
  import EtheloApi.Helpers.QueryHelper
  import EtheloApi.Helpers.ValidationHelper

  defdelegate default_category_slug(), to: OptionCategory

  def valid_filters() do
    [:slug, :id, :decision_id, :deleted, :quadratic]
  end

  @doc """
  private method to start querying with acceptable preloads
  """
  def base_query() do
    OptionCategory |> preload([:decision, :options])
  end

  def match_query(decision_id, filters) do
    filters = Map.put(filters, :decision_id, decision_id)

    OptionCategory
    |> filter_query(filters, valid_filters())
  end

  defp maybe_update_hashes(record, decision, changes) do
    record
    |> Structure.maybe_update_structure_hash(decision, changes)
    |> Structure.maybe_update_decision_weighting_hash(decision, changes)
    |> Structure.maybe_update_decision_influent_hash(decision, changes)
  end

  @doc """
  Returns the list of OptionCategory records for a Decision.
  Optionally filter by field, or return a subset of fields instead of an object

  ## Examples

      iex> list_option_categories(decision_id)
      [%OptionCategory{}, ...]

      iex> list_option_categories(decision_id, %{deleted: false})
      [%OptionCategory{}, ...]

      iex> list_option_categories(decision_id, %{}, [:id])
      [%{id: _}, ...]

  """
  def list_option_categories(decision, filters \\ %{}, fields \\ nil)
  def list_option_categories(%Decision{} = decision, filters, fields) do
     list_option_categories(decision.id, filters, fields)
  end
  def list_option_categories(nil, _, _), do: raise ArgumentError, message: "you must supply a Decision"
  def list_option_categories(decision_id, filters, fields) do
    decision_id |> match_query(filters)
      |> only_fields(fields)
      |> only_distinct(filters)
      |> Repo.all
  end

  @doc """
  Returns the list of OptionCategories for a list of Decision ids.

  ## Examples

      iex> match_option_categories(decision_id)
      [%Option{}, ...]

  """
  def match_option_categories(filters \\ %{}, decision_ids)
  def match_option_categories(filters, decision_ids) when is_list(decision_ids) do
    decision_ids = Enum.uniq(decision_ids)

    OptionCategory
    |> where([t], t.decision_id in ^decision_ids)
    |> filter_query(filters, valid_filters())
    |> Repo.all
  end
  def match_option_categories(_, nil), do: raise ArgumentError, message: "you must supply a list of Decision ids"


  @doc """
  Gets a single OptionCategory.

  returns nil if OptionCategory does not exist or does not belong to the specified Decision

  ## Examples

      iex> get_option_category(123, 1)
      %OptionCategory{}

      iex> get_option_category(456, 3)
      nil

  """
  def get_option_category(id, %Decision{} = decision), do: get_option_category(id, decision.id)
  def get_option_category(_, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def get_option_category(nil, _), do:  raise ArgumentError, message: "you must supply an OptionCategory id"
  def get_option_category(id, decision_id) do
    base_query()
    |> Repo.get_by(id: id, decision_id: decision_id)
  end

  @doc """
  Gets the default OptionCategory

  returns nil if OptionCategory does not exist

  ## Examples

      iex> get_default_option_category(1)
      %OptionCategory{}

      iex> get_default_option_category(3)
      nil

  """
  def get_default_option_category(%Decision{} = decision), do: get_default_option_category(decision.id)
  def get_default_option_category(nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def get_default_option_category(decision_id) do
    base_query()
    |> Repo.get_by(slug: default_category_slug(), decision_id: decision_id)
  end


  @doc """
  Creates an OptionCategory.

  ## Examples

      iex> create_option_category(decision, %{title: "This is my title"})
      {:ok, %OptionCategory{}}

      iex> create_option_category(decision, %{title: " "})
      {:error, %Ecto.Changeset{}}

  """
  def create_option_category(decision, attrs, post_process \\ true)
  def create_option_category(%Decision{} = decision, %{} = attrs, post_process) do
    EtheloApi.Structure.Queries.Decision.ensure_default_associations(decision)
    result = %OptionCategory{}
      |> OptionCategory.create_changeset(attrs, decision)
      |> Repo.insert()

    if post_process do
      Structure.ensure_filters_and_vars(result, decision, %{new: true})
      maybe_update_hashes(result, decision, %{new: true})
    end

    result
  end
  def create_option_category(_, _, _), do: raise ArgumentError, message: "you must supply a Decision"

  @doc """
  Creates the default "uncategorized" OptionCategory if it does not exist.
  This does not return a record.

  This method should only be used internally and should never be exposed via api

  ## Examples

      iex> ensure_default_option_category(decision)
      :ok

  """
  def ensure_default_option_category(%Decision{id: _} = decision) do
    #upsert manually as Ecto 2.1.4 does not support partial index upserts
    #this could have race conditions leading to failure, this is acceptable
    #as in that case a all options filter would still be present

    decision
    |> get_default_option_category()
    |> case do
      %OptionCategory{} = existing -> existing
      _ ->
        insert_default_option_category(decision)
        get_default_option_category(decision)
    end
  end
  def ensure_default_option_category(_), do: raise ArgumentError, message: "you must supply a Decision"

  defp insert_default_option_category(decision) do
    decision
    |> OptionCategory.default_category_changeset()
    |> Repo.insert()
  end

  @doc """
  Updates an OptionCategory.
  Note: this method will not change the Decision an OptionCategory belongs to.
  Default Category cannot be updated

  ## Examples

      iex> update_option_category(option_category, %{field: new_value})
      {:ok, %OptionCategory{}}

      iex> update_option_category(option_category, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_option_category(%OptionCategory{} = option_category, %{} = attrs, post_process \\ true) do
    changeset = option_category |> OptionCategory.update_changeset(attrs)
    result = changeset |> Repo.update()

    if post_process do
      Structure.ensure_filters_and_vars(result, option_category.decision_id, changeset.changes)
      maybe_update_hashes(result, option_category.decision_id, changeset.changes)
    end

    result
  end

  @doc """
  Deletes an OptionCategory.

  ## Examples

      iex> delete_option_category(option_category, decision_id)
      {:ok, %OptionCategory{}, decision_id}

  """
  def delete_option_category(id, %Decision{} = decision), do: delete_option_category(id, decision.id)
  def delete_option_category(%OptionCategory{} = option_category, decision_id), do: delete_option_category(option_category.id, decision_id)
  def delete_option_category(_, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def delete_option_category(nil, _), do:  raise ArgumentError, message: "you must supply an OptionCategory id"
  def delete_option_category(id, decision_id) do
    id
    |> get_option_category(decision_id)
    |> do_delete()
  end

  @default_category_slug OptionCategory.default_category_slug()
  def do_delete(nil), do: {:ok, nil}
  def do_delete(%OptionCategory{slug: @default_category_slug}) do
    {:error, protected_record_changeset(OptionCategory, :id)}
  end
  def do_delete(%OptionCategory{options: [_]}) do
    {:error, protected_record_changeset(OptionCategory, :id)}
  end
  def do_delete(%OptionCategory{options: [_|_]}) do
    {:error, protected_record_changeset(OptionCategory, :id)}
  end
  def do_delete(%OptionCategory{options: []} = option_category) do
    Repo.delete(option_category)
    |> maybe_update_hashes(option_category.decision_id, %{deleted: true})
  end

end
