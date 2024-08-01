defmodule EtheloApi.Structure.Queries.Variable do
  @moduledoc """
  Contains methods that will be delegated to inside structure.
  Used purely to reduce the size of structure.ex
  """

  import Ecto.Query, warn: false
  import EtheloApi.Helpers.ValidationHelper
  import EtheloApi.Helpers.QueryHelper

  alias EtheloApi.Repo
  alias EtheloApi.Structure
  alias EtheloApi.Structure.Variable
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Constraints.VariableBuilder

  def valid_filters() do
    [:slug, :id, :option_filter_id, :option_detail_id, :decision_id]
  end

  @doc """
  private method to start querying with acceptable preloads
  """
  def base_query() do
    Variable
  end

  def match_query(decision_id, filters) do
    filters = Map.put(filters, :decision_id, decision_id)

    Variable
    |> preload([:option_detail, :option_filter, :calculations])
    |> filter_query(filters, valid_filters())
  end

  @doc """
  Returns the list of Variables for a Decision.

  ## Examples

      iex> list_variables(decision_id)
      [%Variable{}, ...]

  """
  def list_variables(decision, filters \\ %{})
  def list_variables(%Decision{} = decision, filters), do: list_variables(decision.id, filters)
  def list_variables(nil, _), do: raise ArgumentError, message: "you must supply a Decision"
  def list_variables(decision_id, filters) do
    decision_id |> match_query(filters) |> Repo.all
  end

  @doc """
  Returns a list of matching Variables for a list of Decision ids.

  ## Examples

      iex> match_variables(decision_id)
      [%Variable{}, ...]

  """
  def match_variables(filters \\ %{}, decision_ids)
  def match_variables(filters, decision_ids) when is_list(decision_ids) do
    decision_ids = Enum.uniq(decision_ids)

    Variable
    |> preload(:calculations)
    |> where([t], t.decision_id in ^decision_ids)
    |> filter_query(filters, valid_filters())
    |> Repo.all
  end
  def match_variables(_, nil), do: raise ArgumentError, message: "you must supply a list of Decision ids"


  @doc """
  Gets a single Variable.

  returns nil if Variable does not exist or does not belong to the specified Decision

  ## Examples

      iex> get_variable(123, 1)
      %Variable{}

      iex> get_variable(456, 3)
      nil

  """
  def get_variable(id, %Decision{} = decision), do: get_variable(id, decision.id)
  def get_variable(_, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def get_variable(nil, _), do:  raise ArgumentError, message: "you must supply a Variable id"
  def get_variable(id, decision_id) do
    base_query()
    |> preload([:calculations, :option_detail, :option_filter])
    |> Repo.get_by(id: id, decision_id: decision_id)
  end

  @doc """
  Creates a Variable.

  ## Examples

      iex> create_variable(decision, %{title: "This is my title"})
      {:ok, %Variable{}}

      iex> create_variable(decision, %{title: " "})
      {:error, %Ecto.Changeset{}}

  """
  def create_variable(decision, attrs, update_hash \\ true)
  def create_variable(%Decision{} = decision, %{} = attrs, update_hash) do
    result = %Variable{}
    |> Variable.create_changeset(attrs, decision)
    |> Repo.insert()
    if update_hash, do: Structure.maybe_update_structure_hash(result, decision.id, %{new: true})
    result
  end
  def create_variable(_, _, _), do: raise ArgumentError, message: "you must supply a Decision"

  @doc """
  Updates a Variable.
  Note: this method will not change the Decision a Variable belongs to.

  ## Examples

      iex> update_variable(variable, %{field: new_value})
      {:ok, %Variable{}}

      iex> update_variable(variable, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_variable(%Variable{} = variable, %{} = attrs) do
    changeset = variable |> Variable.update_changeset(attrs)
    changeset
    |> Repo.update()
    |> Structure.maybe_update_structure_hash(variable.decision_id, changeset.changes)
  end

  @doc """
  Updates a Variable without validationg if slug is in use.
  Note: this method will not change the Decision a Variable belongs to.

  ## Examples

      iex> update_used_variable(variable, %{field: new_value})
      {:ok, %Variable{}}

      iex> update_used_variable(variable, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_used_variable(%Variable{} = variable, %{} = attrs) do
    old_slug = variable.slug
    changeset = variable |> Variable.used_variable_changeset(attrs)
    result = changeset |> Repo.update()

    result |> update_calculations(old_slug)
    result |> Structure.maybe_update_structure_hash(variable.decision_id, changeset.changes)
  end

  def update_calculations({:error, _} = variable, _), do: variable
  def update_calculations({_status, value}, old_slug), do: update_calculations(value, old_slug)
  def update_calculations(%Variable{} = variable, old_slug) do
    calculations = base_query()
    |> preload([:calculations])
    |> Repo.get_by(id: variable.id, decision_id: variable.decision_id)
    |> Map.get(:calculations)

    Enum.each(calculations, fn(calculation) ->
      Structure.replace_variable_in_calculation(calculation, old_slug, variable.slug)
    end)
  end

  @doc """
  Deletes a Variable.

  ## Examples

      iex> delete_variable(variable, decision_id)
      {:ok, %Variable{}, decision_id}

  """
  def delete_variable(id, %Decision{} = decision), do: delete_variable(id, decision.id)
  def delete_variable(%Variable{} = variable, decision_id), do: delete_variable(variable.id, decision_id)
  def delete_variable(_, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def delete_variable(nil, _), do:  raise ArgumentError, message: "you must supply a Variable id"
  def delete_variable(id, decision_id) do
    id |> get_variable(decision_id) |> do_delete_variable()
  end

  defp do_delete_variable(nil), do: {:ok, nil}
  defp do_delete_variable(%Variable{} = variable) do
    variable = Repo.preload(variable, [:calculations])
    if Enum.count(variable.calculations) > 0 do
      {:error, protected_record_changeset(Variable, :id)}
    else
      Repo.delete(variable)
      |> Structure.maybe_update_structure_hash(variable.decision_id, %{deleted: true})

    end
  end

  @doc """
  Returns the list of suggested Variables for a Decision.

  ## Examples

      iex> suggested_variables(decision)
      [%Variable{}, ...]

  """
  def suggested_variables(%Decision{} = decision), do: suggested_variables(decision.id)
  def suggested_variables(nil), do: raise ArgumentError, message: "you must supply a Decision"
  def suggested_variables(decision_id) do
    option_details = Structure.list_option_details(decision_id)
    option_filters = Structure.list_option_filters(decision_id)
    VariableBuilder.suggested_variables(option_details, option_filters)
  end

  @doc """
  Creates Variables from a list of suggestions

  ## Examples

      iex> suggested_variables(list, decision)
      [%Variable{}, ...]

  """
  def create_suggested_variables(_, nil), do: raise ArgumentError, message: "you must supply a Decision"
  def create_suggested_variables([], _), do: []
  def create_suggested_variables(list, %Decision{} = decision) when is_list(list) do
    result = VariableBuilder.create_suggested_variables(list, decision)
    result
  end
  def create_suggested_variables(_, _), do: raise ArgumentError, message: "you must supply a list of suggested variables"


  @doc """
  Returns the list of suggested Variables for a Decision.

  ## Examples

      iex> suggested_variables(decision)
      [%Variable{}, ...]

  """
  def valid_variables(%Decision{} = decision), do: valid_variables(decision.id)
  def valid_variables(nil), do: raise ArgumentError, message: "you must supply a Decision"
  def valid_variables(decision_id) do
    option_details = Structure.list_option_details(decision_id)
    option_filters = Structure.list_option_filters(decision_id)
    VariableBuilder.valid_variables(option_details, option_filters)
  end
end
