defmodule EtheloApi.Voting.OptionCategoryBinVote do
  use DocsComposer, module: EtheloApi.Voting.Docs.OptionCategoryBinVote

  @moduledoc """
  #{@doc_map.strings.option_category_bin_vote}

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
  alias EtheloApi.Structure.Criteria
  alias EtheloApi.Structure.OptionCategory
  alias EtheloApi.Voting.OptionCategoryBinVote

  schema "option_category_bin_votes" do
    belongs_to :decision, Decision, on_replace: :raise
    belongs_to :criteria, Criteria, on_replace: :delete
    belongs_to :participant, Participant, on_replace: :delete
    belongs_to :option_category, OptionCategory, on_replace: :delete

    field :bin, :integer

    timestamps(type: :utc_datetime)
  end

  defp base_changeset(%OptionCategoryBinVote{} = option_category_bin_vote, attrs) do
    option_category_bin_vote
    |> cast(attrs, [:participant_id, :criteria_id, :option_category_id, :bin])
  end

  @doc """
  Validates creation of an OptionCategoryBinVote on a Decision.
  """
  def create_changeset(attrs, %Decision{} = decision) do
    %OptionCategoryBinVote{}
    |> base_changeset(attrs)
    |> put_assoc(:decision, decision, required: true)
    |> add_validations(decision)
  end

  @doc """
  Validates update of an OptionCategoryBinVote.

  Does not allow changing of Decision.
  """
  def update_changeset(%OptionCategoryBinVote{} = option_category_bin_vote, attrs) do
    option_category_bin_vote =
      option_category_bin_vote
      |> Repo.preload([:decision, :option_category_id, :criteria, :participant])

    option_category_bin_vote
    |> base_changeset(attrs)
    |> add_validations(option_category_bin_vote.decision_id)
  end

  @doc """
  """
  def add_validations(%Ecto.Changeset{} = changeset, decision_id) do
    changeset
    |> validate_required([:participant_id, :option_category_id, :criteria_id, :bin])
    |> validate_number(:bin, greater_than_or_equal_to: 1, less_than_or_equal_to: 9)
    |> validate_assoc_in_decision(decision_id, :criteria_id, Criteria)
    |> validate_assoc_in_decision(decision_id, :option_category_id, OptionCategory)
    |> validate_assoc_in_decision(decision_id, :participant_id, Participant)
    |> unique_constraint(:bin, name: :unique_p_oc_bin_vote_index)
    |> foreign_key_constraint(:decision_id)
    |> foreign_key_constraint(:participant_id)
    |> foreign_key_constraint(:criteria_id)
    |> foreign_key_constraint(:option_category_id)
  end
end
