defmodule EtheloApi.Structure.OptionDetailValue do
  use DocsComposer, module: EtheloApi.Structure.Docs.OptionDetailValue

  @moduledoc """
  #{@doc_map.strings.option_detail_value}

  ## Fields
  #{schema_fields(@doc_map.fields)}

  ## Example
  #{@doc_map.strings.mini_tutorial}
  """
  use Ecto.Schema
  import Ecto.Changeset
  use Timex.Ecto.Timestamps

  import EtheloApi.Helpers.ValidationHelper
  alias EtheloApi.Structure.Decision
  alias EtheloApi.Structure.Option
  alias EtheloApi.Structure.OptionDetail
  alias EtheloApi.Structure.OptionDetailValue

  @primary_key false
  schema "option_detail_values" do
    belongs_to :decision, Decision, on_replace: :raise
    belongs_to :option, Option, on_replace: :raise, primary_key: true
    belongs_to :option_detail, OptionDetail, on_replace: :raise, primary_key: true

    field :value, :string
    timestamps()
  end

  def create_changeset(%OptionDetailValue{} = option_detail_value, attrs, decision) do
    attrs = attrs |> stringify_value(:value)

    option_detail_value
    |> cast(attrs, [:value, :option_id, :option_detail_id])
    |> put_assoc(:decision, decision, required: true)
    |> validate_option(decision)
    |> validate_option_detail(decision)
    |> unique_constraint(:option_detail, name: :option_detail_values_pkey)
  end

  defp validate_option(changeset, decision) do
    {changeset, _, _} = validate_assoc_in_decision(changeset, decision, :option_id, Option)
    changeset
  end

  defp validate_option_detail(changeset, decision) do
    {changeset, _, _} = validate_assoc_in_decision(changeset, decision, :option_detail_id, OptionDetail)
    changeset
  end

  @doc """
  Validates update of an OptionDetailValue on an option.

  Neither the Option or the OptionDetail can be changed.
  """
  def update_changeset(%OptionDetailValue{} = option_detail_value, attrs) do
    attrs = attrs |> stringify_value(:value)

    option_detail_value |> cast(attrs, [:value])
  end

  @doc """
  Validations for bulk upsert, cannot contain any database lookups
  """
  def bulk_upsert_changeset(%{} = attrs) do
    %OptionDetailValue{}
    |> cast(attrs, [:value, :option_id, :option_detail_id, :inserted_at, :updated_at, :decision_id])
    |> validate_required([:value, :option_id, :option_detail_id, :inserted_at, :updated_at, :decision_id])
  end

end
