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

    timestamps(type: :utc_datetime)
  end

  defp base_changeset(%OptionCategoryRangeVote{} = option_category_range_vote, attrs) do
    option_category_range_vote
    |> cast(attrs, [:participant_id, :low_option_id, :high_option_id, :option_category_id])
  end

  defp validate_option_in_option_category(changeset, key_field) do
    if field_missing?(changeset, key_field) || field_missing?(changeset, :option_category_id) do
      changeset
    else
      option_id = get_field(changeset, key_field)
      option_category_id = get_field(changeset, :option_category_id)

      object = Repo.get_by(Option, %{option_category_id: option_category_id, id: option_id})
      changeset |> validate_foreign_presence(key_field, object)
    end
  end

  @doc """
  Validates creation of an OptionCategoryRangeVote on a Decision.
  """
  def create_changeset(attrs, %Decision{} = decision) do
    %OptionCategoryRangeVote{}
    |> base_changeset(attrs)
    |> put_assoc(:decision, decision, required: true)
    |> add_validations(decision)
  end

  @doc """
  Validates update of an OptionCategoryRangeVote.

  Does not allow changing of Decision.
  """
  def update_changeset(%OptionCategoryRangeVote{} = option_category_range_vote, attrs) do
    option_category_range_vote =
      option_category_range_vote
      |> Repo.preload([:decision, :low_option, :high_option, :option_category, :participant])

    option_category_range_vote
    |> base_changeset(attrs)
    |> add_validations(option_category_range_vote.decision_id)
  end

  @doc """
  Adds validations shared between update and create actions
  """
  def add_validations(%Ecto.Changeset{} = changeset, decision_id) do
    changeset
    |> validate_required([:participant_id, :option_category_id, :low_option_id])
    |> validate_assoc_in_decision(decision_id, :option_category_id, OptionCategory)
    |> validate_assoc_in_decision(decision_id, :participant_id, Participant)
    |> validate_assoc_in_decision(decision_id, :low_option_id, Option)
    |> validate_optional_assoc_in_decision(decision_id, :high_option_id, Option)
    |> validate_option_in_option_category(:high_option_id)
    |> validate_option_in_option_category(:low_option_id)
    |> unique_constraint(:option_category, name: :unique_p_oc_range_vote)
    |> foreign_key_constraint(:decision_id)
    |> foreign_key_constraint(:participant_id)
    |> foreign_key_constraint(:option_category_id)
    |> foreign_key_constraint(:high_option_id)
    |> foreign_key_constraint(:low_option_id)
  end
end
