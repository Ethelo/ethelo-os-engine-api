defmodule EtheloApi.Voting.Queries.Participant do
  @moduledoc """
  Contains methods that will be delegated to inside EtheloApi.Voting.
  Used purely to reduce the size of voting.ex
  """

  import Ecto.Query, warn: false
  import EtheloApi.Helpers.QueryHelper

  alias EtheloApi.Repo
  alias EtheloApi.Voting.Participant
  alias EtheloApi.Structure.Decision

  @doc """
  private method to start querying with acceptable preloads
  """
  def base_query() do
    Participant |> preload([:decision])
  end

  def valid_filters() do
    [:auxiliary, :id]
  end

  @doc """
  Returns the list of Participants for a Decision.

  ## Examples

      iex> list_participants(decision_id)
      [%Participant{}, ...]

  """
  def list_participants(decision, filters \\ %{})
  def list_participants(%Decision{} = decision, filters), do: list_participants(decision.id, filters)
  def list_participants(nil, _), do: raise ArgumentError, message: "you must supply a Decision"
  def list_participants(decision_id, filters) do
    base_query()
    |> where([t], t.decision_id == ^decision_id)
    |> filter_query(filters, valid_filters())
    |> Repo.all
  end

  @doc """
  Gets a single participant.

  returns nil if Participant does not exist or does not belong to the specified Decision

  ## Examples

      iex> get_participant(123, 1)
      %Participant{}

      iex> get_participant(456, 3)
      nil

  """
  def get_participant(id, %Decision{} = decision), do: get_participant(id, decision.id)
  def get_participant(_, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def get_participant(nil, _), do:  raise ArgumentError, message: "you must supply a Participant id"
  def get_participant(id, decision_id) do
    base_query() |> Repo.get_by(id: id, decision_id: decision_id)
  end

  @doc """
  Creates an participant.

  ## Examples

      iex> create_participant(decision, %{title: "This is my title"})
      {:ok, %Participant{}}

      iex> create_participant(decision, %{title: " "})
      {:error, %Ecto.Changeset{}}

  """
  def create_participant(%Decision{} = decision, %{} = attrs) do
    %Participant{}
    |> Participant.create_changeset(attrs, decision)
    |> Repo.insert()
  end
  def create_participant(_, _), do: raise ArgumentError, message: "you must supply a Decision"

  @doc """
  Updates an participant.
  Note: this method will not change the Decision a Participant belongs to.

  ## Examples

      iex> update_participant(participant, %{field: new_value})
      {:ok, %Participant{}}

      iex> update_participant(participant, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_participant(%Participant{} = participant, %{} = attrs) do
    result = participant
    |> Participant.update_changeset(attrs)
    |> Repo.update()
    update_participant_influent_hash(participant)
    result
  end

  def update_participant_influent_hash(%Participant{} = participant) do
    case Engine.Invocation.generate_participant_influent_hash(participant)  do
      {:ok, hash} ->
        Ecto.Changeset.change(participant, %{influent_hash: hash})
        |> Repo.update()
      error -> error
    end
  end
  def update_participant_influent_hash(participant_id, decision_id) do
    get_participant(participant_id, decision_id) |> update_participant_influent_hash
  end


  @doc """
  Deletes a Participant.

  ## Examples

      iex> delete_participant(participant, decision_id)
      {:ok, %Participant{}, decision_id}

  """
  def delete_participant(id, %Decision{} = decision), do: delete_participant(id, decision.id)
  def delete_participant(%Participant{} = participant, decision_id), do: delete_participant(participant.id, decision_id)
  def delete_participant(_, nil), do: raise ArgumentError, message: "you must supply a Decision id"
  def delete_participant(nil, _), do:  raise ArgumentError, message: "you must supply a Participant id"
  def delete_participant(id, decision_id) do
    id
    |> get_participant(decision_id)
    |> case do
      nil -> {:ok, nil}
      participant -> Repo.delete(participant)
    end
  end
end
