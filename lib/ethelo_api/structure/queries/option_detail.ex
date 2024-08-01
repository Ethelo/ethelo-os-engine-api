defmodule EtheloApi.Structure.Queries.OptionDetail do
  @moduledoc """
  Contains methods that will be delegated to inside structure.
  Used purely to reduce the size of structure.ex
  """

  import Ecto.Query, warn: false
  import EtheloApi.Helpers.EctoHelper
  alias EtheloApi.Repo
  alias EtheloApi.Structure
  alias EtheloApi.Structure.OptionDetail
  alias EtheloApi.Structure.Decision

  def valid_filters() do
    [:slug, :id, :decision_id, :format]
  end

  def match_query(decision_id, modifiers) do
    modifiers = Map.put(modifiers, :decision_id, decision_id)

    OptionDetail
    |> filter_query(modifiers, valid_filters())
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
  def list_option_details(decision, modifiers \\ %{}, fields \\ nil)

  def list_option_details(%Decision{} = decision, modifiers, fields) do
    list_option_details(decision.id, modifiers, fields)
  end

  def list_option_details(nil, _, _),
    do: raise(ArgumentError, message: "you must supply a Decision")

  def list_option_details(decision_id, modifiers, fields) do
    decision_id
    |> match_query(modifiers)
    |> only_fields(fields)
    |> only_distinct(modifiers)
    |> Repo.all()
  end

  @doc """
  Checks if there exists an OptionDetail that matches the given query.

  Returns a boolean.


  ## Examples

      iex> option_detail_exists(decision_id)
      true

      iex> option_detail_exists(decision_id, %{format: [:integer, :float], id: 23})
      false
  """
  def option_detail_exists(decision, modifiers \\ %{})

  def option_detail_exists(%Decision{} = decision, modifiers) do
    option_detail_exists(decision.id, modifiers)
  end

  def option_detail_exists(nil, _),
    do: raise(ArgumentError, message: "you must supply a Decision")

  def option_detail_exists(decision_id, modifiers) do
    decision_id
    |> match_query(modifiers)
    |> Repo.exists?()
  end

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

  def get_option_detail(_, nil),
    do: raise(ArgumentError, message: "you must supply a Decision id")

  def get_option_detail(nil, _),
    do: raise(ArgumentError, message: "you must supply an OptionDetail id")

  def get_option_detail(id, decision_id) do
    OptionDetail |> Repo.get_by(id: id, decision_id: decision_id)
  end

  @doc """
  Creates an OptionDetail.

  ## Examples

      iex> create_option_detail(decision, %{title: "This is my title"})
      {:ok, %OptionDetail{}}

      iex> create_option_detail(decision, %{title: " "})
      {:error, %Ecto.Changeset{}}

  """
  def create_option_detail(attrs, decision, post_process \\ true)

  def create_option_detail(%{} = attrs, %Decision{} = decision, post_process) do
    result =
      attrs
      |> OptionDetail.create_changeset(decision)
      |> Repo.insert()

    if post_process do
      Structure.ensure_filters_and_vars(result, decision, %{new: true})
      Structure.maybe_update_structure_hash(result, decision, %{new: true})
    end

    result
  end

  def create_option_detail(_, _, _),
    do: raise(ArgumentError, message: "you must supply a Decision")

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
    result = changeset |> Repo.update()

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

  def delete_option_detail(%OptionDetail{} = option_detail, decision_id),
    do: delete_option_detail(option_detail.id, decision_id)

  def delete_option_detail(_, nil),
    do: raise(ArgumentError, message: "you must supply a Decision id")

  def delete_option_detail(nil, _),
    do: raise(ArgumentError, message: "you must supply an OptionDetail id")

  def delete_option_detail(id, decision_id) do
    id
    |> get_option_detail(decision_id)
    |> case do
      nil ->
        {:ok, nil}

      option_detail ->
        Repo.delete(option_detail)
        |> Structure.maybe_update_structure_hash(decision_id, %{deleted: true})
    end
  end
end
