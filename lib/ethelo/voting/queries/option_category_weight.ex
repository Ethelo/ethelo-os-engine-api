defmodule EtheloApi.Voting.Queries.OptionCategoryWeight do
  @moduledoc """
  Contains methods that will be delegated to inside EtheloApi.Voting.
  Used purely to reduce the size of voting.ex
  """

  import Ecto.Query, warn: false
  import EtheloApi.Helpers.QueryHelper

  alias EtheloApi.Repo
  alias EtheloApi.Voting.OptionCategoryWeight
  alias EtheloApi.Voting
  alias EtheloApi.Structure.Decision

  @doc """
  private method to start querying with acceptable preloads
  """
  def base_query() do
    OptionCategoryWeight |> preload([:decision, :participant, :option_category])
  end

  def valid_filters() do
    [:participant_id, :option_category_id]
  end

  @doc """
  Returns the list of OptionCategoryWeights for a Decision.

  ## Examples

      iex> list_option_category_weights(decision_id)
      [%OptionCategoryWeight{}, ...]

  """
  def list_option_category_weights(decision, filters \\ %{})
  def list_option_category_weights(%Decision{} = decision, filters), do: list_option_category_weights(decision.id, filters)
  def list_option_category_weights(nil, _), do: raise ArgumentError, message: "you must supply a Decision"
  def list_option_category_weights(decision_id, filters) do
    base_query()
    |> where([t], t.decision_id == ^decision_id)
    |> filter_query(filters, valid_filters())
    |> Repo.all
  end

  @doc """
  Returns the list of matching OptionCategoryWeights for a Decision.
  Used for batch processing

  ## Examples

      iex> match_option_category_weights(filters, decision_id)
      [%OptionCategoryWeight{}, ...]

  """
  def match_option_category_weights(filters \\ %{}, decision_ids)
  def match_option_category_weights(filters, decision_ids) when is_list(decision_ids) do
    decision_ids = Enum.uniq(decision_ids)
    OptionCategoryWeight
    |> where([t], t.decision_id in ^decision_ids)
    |> filter_query(filters, valid_filters())
    |> Repo.all
  end
  def match_option_category_weights(_, nil), do: raise ArgumentError, message: "you must supply a list of Decision ids"


  @doc """
  Gets a single option_category_weight.

  returns nil if OptionCategoryWeight does not exist or does not belong to the specified Decision

  ## Examples

      iex> get_option_category_weight(123, 1)
      %OptionCategoryWeight{}

      iex> get_option_category_weight(456, 3)
      nil

  """
  def get_option_category_weight(id, %Decision{} = decision), do: get_option_category_weight(id, decision.id)
  def get_option_category_weight(_, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def get_option_category_weight(nil, _), do:  raise ArgumentError, message: "you must supply an OptionCategoryWeight id"
  def get_option_category_weight(id, decision_id) do
    base_query() |> Repo.get_by(id: id, decision_id: decision_id)
  end

  @doc """
  Upserts an option_category_weight.

  ## Examples

      iex> upsert_option_category_weight(decision, %{title: "This is my title"})
      {:ok, %OptionCategoryWeight{}}

      iex> upsert_option_category_weight(decision, %{title: " "})
      {:error, %Ecto.Changeset{}}

  """
  def upsert_option_category_weight(decision, attrs)
  def upsert_option_category_weight(%Decision{} = decision, %{} = attrs) do
    %OptionCategoryWeight{}
    |> OptionCategoryWeight.create_changeset(attrs, decision)
    |> Repo.insert([upsert: true] |> handle_conflicts([:option_category_id, :participant_id]))
    |> Voting.maybe_update_voting_hashes(attrs, decision.id, :weighting)

  end
  def upsert_option_category_weight(_, _), do: raise ArgumentError, message: "you must supply a Decision"


  @doc """
  Deletes a OptionCategoryWeight.

  ## Examples

      iex> delete_option_category_weight(option_category_weight, decision_id)
      {:ok, %OptionCategoryWeight{}, decision_id}

  """
  def delete_option_category_weight(id, %Decision{} = decision), do: delete_option_category_weight(id, decision.id)
  def delete_option_category_weight(%OptionCategoryWeight{} = option_category_weight, decision_id), do: delete_option_category_weight(option_category_weight.id, decision_id)
  def delete_option_category_weight(
  %{participant_id: participant_id, option_category_id: option_category_id},
  decision_id) do
    OptionCategoryWeight
    |> Repo.get_by(participant_id: participant_id, option_category_id: option_category_id, decision_id: decision_id)
    |> case do
      nil -> {:ok, nil}
      option_category_weight ->
        Repo.delete(option_category_weight)
        |> Voting.maybe_update_voting_hashes(option_category_weight, decision_id, :weighting)
      end
  end
  def delete_option_category_weight(_, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def delete_option_category_weight(nil, _), do:  raise ArgumentError, message: "you must supply an OptionCategoryWeight id"
  def delete_option_category_weight(id, decision_id) do
    id
    |> get_option_category_weight(decision_id)
    |> case do
      nil -> {:ok, nil}
      option_category_weight ->
        Repo.delete(option_category_weight)
        |> Voting.maybe_update_voting_hashes(option_category_weight, decision_id, :weighting)

    end
  end

end
