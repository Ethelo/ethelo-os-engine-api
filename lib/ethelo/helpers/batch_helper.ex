defmodule EtheloApi.Helpers.BatchHelper do
  @moduledoc """
  Helper Methods for batch loading records associated with Decisions
  """

  @doc """
  Checks if an association has been preloaded and returns the value if present

  ## Examples

      iex> preloaded_assoc(parent, assocaition)
      {:ok, %Associated{}}

      iex> preloaded_assoc(parent, association)
      {:error, nil}

  """
  def preloaded_assoc(record, association) do
    case Map.get(record, association) do
      %Ecto.Association.NotLoaded{} ->
        {:error, nil}
      val ->
        {:ok, val}
    end
  end

  @doc """
  returns id of associated record

  ## Examples

      iex> assoc_info(parent, assocaition)
      {:ok, 12}

  """
  def associated_id(%schema{} = parent, assoc_field) do
    assoc = assoc_info(schema, assoc_field)
    Map.fetch!(parent, assoc.owner_key)
  end

  @doc """
  Batch load records through an association.
  """
  def batch_assoc(repo, assoc_field, schema, ids) do
    %{owner: owner, owner_key: owner_key, field: field} = assoc_info(schema, assoc_field)

    ids
    |> MapSet.new
    |> MapSet.to_list
    |> Enum.map(&Map.put(struct(owner), owner_key, &1))
    |> repo.preload(field)
    |> Enum.map(&{Map.get(&1, owner_key), Map.get(&1, field)})
    |> Map.new
  end

  def map_by_decision_id(nil), do: nil
  def map_by_decision_id(records) do
    records |> Enum.map(&{Map.get(&1, :decision_id), &1}) |> Map.new
  end

  def assoc_info(schema, assoc_field) do
    assoc = schema.__schema__(:association, assoc_field)
    Map.take(assoc, [:owner, :owner_key, :field])
  end

end
