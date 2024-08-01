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
    timestamps(type: :utc_datetime)
  end

  def base_changeset(attrs) do
    attrs = attrs |> stringify_value(:value)

    %OptionDetailValue{}
    |> cast(attrs, [:value])
  end

  def cast_associations(changeset, attrs) do
    changeset |> cast(attrs, [:option_id, :option_detail_id])
  end

  def upsert_changeset(attrs, %Decision{} = decision) do
    base_changeset(attrs)
    |> cast_associations(attrs)
    |> put_assoc(:decision, decision, required: true)
    |> basic_validations()
    |> db_validations(decision.id)
  end

  @doc """
  Validations for bulk upsert, cannot contain any database lookups
  """
  def import_assoc_changeset(attrs, decision_id) do
    base_changeset(attrs)
    |> cast_associations(attrs)
    |> basic_validations()
    |> validate_import_required(decision_id)
    |> validate_required([:option_id, :option_detail_id])
  end

  def basic_validations(changeset) do
    changeset
    # put errors in :option_detail field
    |> unique_constraint(:option_detail, name: :option_detail_values_pkey)
    |> foreign_key_constraint(:decision_id)
    |> foreign_key_constraint(:option_detail_id)
    |> foreign_key_constraint(:option_id)
  end

  def db_validations(changeset, decision) do
    changeset
    |> validate_assoc_in_decision(decision, :option_id, Option)
    |> validate_assoc_in_decision(decision, :option_detail_id, OptionDetail)
  end

  def export_fields() do
    [
      :option_id,
      :option_detail_id,
      :value
    ]
  end
end
