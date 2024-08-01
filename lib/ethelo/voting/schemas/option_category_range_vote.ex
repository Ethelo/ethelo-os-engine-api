defmodule EtheloApi.Voting.OptionCategoryRangeVote do

  use DocsComposer, module: EtheloApi.Voting.Docs.OptionCategoryRangeVote

  @moduledoc """
  #{@doc_map.strings.option_category_range_vote}

  ## Fields
  #{schema_fields(@doc_map.fields)}

  ## Examples
  #{schema_examples(@doc_map.examples)}
  """

  use Ecto.Schema
  use Timex.Ecto.Timestamps
  import Ecto.Changeset
  import Ecto.Query, warn: false

  import EtheloApi.Helpers.ValidationHelper
  alias EtheloApi.Repo
  alias EtheloApi.Voting.Participant
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.OptionCategory
  alias EtheloApi.Structure.Option
  alias EtheloApi.Voting.OptionCategoryRangeVote

  schema "option_category_range_votes" do
    belongs_to :decision, Decision, on_replace: :raise
    belongs_to :participant, Participant, on_replace: :delete
    belongs_to :option_category, OptionCategory, on_replace: :delete
    belongs_to :low_option, Option, on_replace: :delete
    belongs_to :high_option, Option, on_replace: :delete

    timestamps()
  end

  @doc """
  Adds validations shared between update and create actions
  - required fields: participant_id, bin, low_option_id
  - bin between 1..100
  - validate Option
  - validate Participant
  """
  def add_validations(%Ecto.Changeset{} = changeset, decision) do
    changeset
    |> validate_required([:participant_id, :option_category_id, :low_option_id])
    |> validate_option_category(decision)
    |> validate_low_option(decision)
    |> maybe_validate_high_option(decision)
    |> maybe_validate_option_in_option_category(:high_option_id)
    |> maybe_validate_option_in_option_category(:low_option_id)
    |> validate_participant(decision)
    |> unique_constraint(:option_category, name: :unique_p_oc_range_vote)
  end

  defp base_changeset(%OptionCategoryRangeVote{} = option_category_range_vote, attrs) do
    option_category_range_vote
    |> cast(attrs, [:participant_id, :low_option_id, :high_option_id, :option_category_id])
  end

  defp validate_low_option(changeset, decision) do
    {changeset, _, _} = validate_assoc_in_decision(changeset, decision, :low_option_id, Option)
    changeset
  end

  defp maybe_validate_high_option(changeset, decision) do
    case get_field(changeset, :high_option_id) do
      nil -> changeset
      _ -> {changeset, _, _} = validate_assoc_in_decision(changeset, decision, :high_option_id, Option)
          changeset
    end
  end

  defp maybe_validate_option_in_option_category(changeset, key_field) do
    option_id = get_field(changeset, key_field)
    option_category_id = get_field(changeset, :option_category_id)
    maybe_validate_option_in_option_category(changeset, option_id, option_category_id, key_field)
  end

  defp maybe_validate_option_in_option_category(changeset, nil, _, _), do: changeset
  defp maybe_validate_option_in_option_category(changeset, _, nil, _), do: changeset
  defp maybe_validate_option_in_option_category(changeset, option_id, option_category_id, key_field) do
      object = Repo.get_by(Option, %{option_category_id: option_category_id, id: option_id})
      changeset |> validate_foreign_presence(key_field, object)
  end

  defp validate_participant(changeset, decision) do
    {changeset, _, _} = validate_assoc_in_decision(changeset, decision, :participant_id, Participant)
    changeset
  end

  defp validate_option_category(changeset, decision) do
    {changeset, _, _} = validate_assoc_in_decision(changeset, decision, :option_category_id, OptionCategory)
    changeset
  end

  @doc """
  Validates creation of an OptionCategoryRangeVote on a Decision.
  """
  def create_changeset(%OptionCategoryRangeVote{} = option_category_range_vote, attrs, %Decision{} = decision) do
    option_category_range_vote
    |> base_changeset(attrs)
    |> put_assoc(:decision, decision, required: true)
    |> add_validations(decision)
  end

  @doc """
  Validates update of an OptionCategoryRangeVote.

  Does not allow changing of Decision.
  """
  def update_changeset(%OptionCategoryRangeVote{} = option_category_range_vote, attrs) do
    option_category_range_vote = option_category_range_vote
      |> Repo.preload([:decision, :low_option, :high_option, :option_category, :participant])

    option_category_range_vote
    |> base_changeset(attrs)
    |> add_validations(option_category_range_vote.decision)
  end
end
