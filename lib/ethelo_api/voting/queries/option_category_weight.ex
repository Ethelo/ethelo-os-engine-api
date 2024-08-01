defmodule EtheloApi.Voting.Queries.OptionCategoryWeight do
  @moduledoc """
  Contains methods that will be delegated to inside EtheloApi.Voting.
  Used purely to reduce the size of voting.ex
  """

  import Ecto.Query, warn: false
  import EtheloApi.Helpers.EctoHelper

  alias EtheloApi.Repo
  alias EtheloApi.Voting.OptionCategoryWeight
  alias EtheloApi.Voting
  alias EtheloApi.Structure.Decision

  def valid_filters() do
    [:participant_id, :option_category_id, :id]
  end

  @doc """
  Returns the list of OptionCategoryWeights for a Decision.

  ## Examples

      iex> list_option_category_weights(decision_id)
      [%OptionCategoryWeight{}, ...]

  """
  def list_option_category_weights(decision, modifiers \\ %{})

  def list_option_category_weights(%Decision{} = decision, modifiers),
    do: list_option_category_weights(decision.id, modifiers)

  def list_option_category_weights(nil, _),
    do: raise(ArgumentError, message: "you must supply a Decision")

  def list_option_category_weights(decision_id, modifiers) do
    OptionCategoryWeight
    |> where([t], t.decision_id == ^decision_id)
    |> filter_query(modifiers, valid_filters())
    |> Repo.all()
  end

  def match_one_option_category_weight(modifiers \\ %{}, decision_id) do
    OptionCategoryWeight
    |> where([t], t.decision_id == ^decision_id)
    |> filter_query(modifiers, valid_filters())
    |> Repo.one()
  end

  @doc """
  Gets a single OptionCategoryWeight

  returns nil if OptionCategoryWeight does not exist or does not belong to the specified Decision

  ## Examples

      iex> get_option_category_weight(123, 1)
      %OptionCategoryWeight{}

      iex> get_option_category_weight(456, 3)
      nil

  """
  def get_option_category_weight(id, %Decision{} = decision),
    do: get_option_category_weight(id, decision.id)

  def get_option_category_weight(_, nil),
    do: raise(ArgumentError, message: "you must supply a Decision id")

  def get_option_category_weight(nil, _),
    do: raise(ArgumentError, message: "you must supply an OptionCategoryWeight id")

  def get_option_category_weight(id, decision_id) do
    OptionCategoryWeight |> Repo.get_by(id: id, decision_id: decision_id)
  end

  @doc """
  Upserts an OptionCategoryWeight

  ## Examples

      iex> upsert_option_category_weight( %{weighting: 43, option_category_id: 1, participant_id: 1}, decision)
      {:ok, %OptionCategoryWeight{}}

      iex> upsert_option_category_weight( %{weighting: " "}, decision)
      {:error, %Ecto.Changeset{}}

  """

  def upsert_option_category_weight(%{} = attrs, %Decision{} = decision) do
    attrs
    |> OptionCategoryWeight.create_changeset(decision)
    |> Repo.insert(
      on_conflict: {:replace, [:weighting, :updated_at]},
      conflict_target: [:option_category_id, :participant_id],
      returning: true
    )
    |> Voting.maybe_update_influent_hash(attrs, decision.id)
  end

  def upsert_option_category_weight(_, _),
    do: raise(ArgumentError, message: "you must supply a Decision")

  @doc """
  Deletes an OptionCategoryWeight.

  ## Examples

      iex> delete_option_category_weight(option_category_weight, decision_id)
      {:ok, %OptionCategoryWeight{}}

      iex> delete_option_category_weight(option_category_weight, decision_id)
      {:ok, nil}
      iex> delete_option_category_weight(%{particiant_id: 1, option_category_id: 2}, decision_id)
      {:ok, %OptionCategoryWeight{}}
  """
  @spec delete_option_category_weight(
          map() | integer | OptionCategoryWeight.t(),
          map() | integer | Decision.t()
        ) :: {atom, nil | OptionCategoryWeight.t()}
  def delete_option_category_weight(id, %Decision{id: decision_id}),
    do: delete_option_category_weight(id, decision_id)

  def delete_option_category_weight(%OptionCategoryWeight{id: id}, decision_id),
    do: do_delete(%{id: id}, decision_id)

  def delete_option_category_weight(_, nil),
    do: raise(ArgumentError, message: "you must supply a Decision id")

  def delete_option_category_weight(nil, _),
    do: raise_invalid_delete()

  def delete_option_category_weight(
        %{participant_id: nil},
        _decision_id
      ),
      do: raise_invalid_delete()

  def delete_option_category_weight(
        %{option_category_id: nil},
        _decision_id
      ),
      do: raise_invalid_delete()

  def delete_option_category_weight(
        %{participant_id: _, option_category_id: _} = modifiers,
        decision_id
      ),
      do: do_delete(modifiers, decision_id)

  defp do_delete(modifiers, decision_id) do
    match_one_option_category_weight(modifiers, decision_id)
    |> case do
      nil ->
        {:ok, nil}

      option_category_weight ->
        Repo.delete(option_category_weight)
        |> Voting.maybe_update_influent_hash(option_category_weight, decision_id)
    end
  end

  defp raise_invalid_delete,
    do:
      raise(ArgumentError,
        message: "you must supply a CriteriaWeight id  or a map with unique fields "
      )
end
