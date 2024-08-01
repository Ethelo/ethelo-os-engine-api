defmodule EtheloApi.Voting.OptionCategoryWeight do

    use DocsComposer, module: EtheloApi.Voting.Docs.OptionCategoryWeight

    @moduledoc """
    #{@doc_map.strings.option_category_weight}

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
  alias EtheloApi.Voting.OptionCategoryWeight

  schema "option_category_weights" do
    belongs_to :decision, Decision, on_replace: :raise
    belongs_to :option_category, OptionCategory, on_replace: :delete
    belongs_to :participant, Participant, on_replace: :delete

    field :weighting, :integer

    timestamps()
  end

  @doc """
  Adds validations shared between update and create actions
  - required fields: participant_id, weighting, option_category_id
  - weighting between 1..100
  - validate OptionCategory
  - validate Participant
  """
  def add_validations(%Ecto.Changeset{} = changeset, decision) do
    changeset
    |> validate_required([:participant_id, :option_category_id, :weighting])
    |> validate_number(:weighting, greater_than_or_equal_to: 1, less_than_or_equal_to: 100)
    |> validate_option_category(decision)
    |> validate_participant(decision)
    |> unique_constraint(:weighting, name: :unique_participant_filter_weight_index)
  end

  defp base_changeset(%OptionCategoryWeight{} = option_category_weight, attrs) do
    option_category_weight
    |> cast(attrs, [:participant_id, :option_category_id, :weighting])
  end

  defp validate_option_category(changeset, decision) do
    {changeset, _, _} = validate_assoc_in_decision(changeset, decision, :option_category_id, OptionCategory)
    changeset
  end

  defp validate_participant(changeset, decision) do
    {changeset, _, _} = validate_assoc_in_decision(changeset, decision, :participant_id, Participant)
    changeset
  end

  @doc """
  Validates creation of an OptionCategoryWeight on a Decision.
  """
  def create_changeset(%OptionCategoryWeight{} = option_category_weight, attrs, %Decision{} = decision) do
    option_category_weight
    |> base_changeset(attrs)
    |> put_assoc(:decision, decision, required: true)
    |> add_validations(decision)
  end

  @doc """
  Validates update of an OptionCategoryWeight.

  Does not allow changing of Decision.
  """
  def update_changeset(%OptionCategoryWeight{} = option_category_weight, attrs) do
    option_category_weight = option_category_weight |> Repo.preload([:decision, :option_category, :participant])

    option_category_weight
    |> base_changeset(attrs)
    |> add_validations(option_category_weight.decision)
  end
end
