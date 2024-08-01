defmodule EtheloApi.Helpers.ValidationHelper do
  @moduledoc """
  Helper Methods for records associated with Decisions
  """

  alias EtheloApi.Repo
  alias EtheloApi.Helpers.SlugHelper
  alias AbsintheErrorPayload.ValidationMessage
  import Ecto.Changeset

  @doc "quick helper to see if a field has an error"
  def has_error?(changeset, field_name) do
    !is_nil(changeset.errors[field_name])
  end

  @doc """
  verifies that association exists in decision

  first checks that id is passed in, then tries to load the object.
  if loaded value is nil or "". adds a foreign_key_constraint error

  """
  def validate_assoc_in_decision(changeset, %{id: decision_id}, key_field, assoc_module) do
    validate_assoc_in_decision(changeset, decision_id, key_field, assoc_module)
  end

  def validate_assoc_in_decision(changeset, decision_id, key_field, assoc_module) do
    if field_missing?(changeset, key_field) do
      validate_required(changeset, key_field)
    else
      validate_optional_assoc_in_decision(changeset, decision_id, key_field, assoc_module)
    end
  end

  def validate_optional_assoc_in_decision(changeset, %{id: decision_id}, key_field, assoc_module) do
    validate_optional_assoc_in_decision(changeset, decision_id, key_field, assoc_module)
  end

  def validate_optional_assoc_in_decision(changeset, decision_id, key_field, assoc_module) do
    if field_missing?(changeset, key_field) || has_error?(changeset, key_field) do
      changeset
    else
      id_value = get_field(changeset, key_field)
      object = Repo.get_by(assoc_module, %{decision_id: decision_id, id: id_value})
      changeset |> validate_foreign_presence(key_field, object)
    end
  end

  def validate_foreign_presence(changeset, field_name, nil) do
    add_error(changeset, field_name, "does not exist", code: :foreign)
  end

  def validate_foreign_presence(changeset, _field_name, _truthy) do
    changeset
  end

  def validate_either(changeset, field_name1, field_name2, message) do
    field_states =
      {
        get_change_with_empty(changeset, field_name1),
        get_change_with_empty(changeset, field_name2)
      }

    case field_states do
      {nil, nil} ->
        changeset
        |> add_error(field_name1, message, code: :either)
        |> add_error(field_name2, message, code: :either)

      {nil, _} ->
        changeset

      {_, nil} ->
        changeset

      {_, _} ->
        changeset
        |> add_error(field_name1, message, code: :either)
        |> add_error(field_name2, message, code: :either)
    end
  end

  def validate_empty(changeset, field_names, message) when is_list(field_names) do
    for field_name <- field_names, reduce: changeset do
      changeset ->
        validate_empty(changeset, field_name, message)
    end
  end

  def validate_empty(changeset, field_name, message) do
    if field_empty?(changeset, field_name) do
      changeset
    else
      changeset |> add_error(field_name, message, code: :empty)
    end
  end

  def validate_has_word(changeset, field) do
    changeset
    |> validate_format(field, ~r/[[:alnum:]]/u, message: "must include at least one word")
  end

  def validate_not_in_duplicate_list(changeset, field, duplicate_list) do
    validate_change(changeset, field, {:unique, duplicate_list}, fn field, value ->
      if value in duplicate_list,
        do: [{field, {"must be unique", [validation: :unique, code: :unique]}}],
        else: []
    end)
  end

  @doc """
  Generate Slug if necessary, validate presence and uniqueness
  """
  def validate_unique_slug(%Ecto.Changeset{} = changeset, schema) do
    changeset
    |> SlugHelper.maybe_update_slug(fn value, changeset ->
      schema |> SlugHelper.slug_not_found_in_decision(value, changeset)
    end)
  end

  def validate_import_slugs(changeset, duplicate_list) do
    changeset
    |> validate_required([:slug])
    |> validate_has_word(:slug)
    |> validate_not_in_duplicate_list(:slug, duplicate_list)
  end

  def validate_import_required(changeset, decision_id) do
    changeset
    |> add_new_change(:decision_id, decision_id)
    |> add_timestamps()
  end

  def protected_record_changeset(schema, field_name, message \\ "cannot be deleted") do
    schema
    |> Kernel.struct()
    |> Ecto.Changeset.change()
    |> add_error(field_name, message, code: :protected_record)
  end

  def get_change_with_empty(changeset, field_name) do
    if changed?(changeset, field_name) || field_name in changeset.required do
      get_change(changeset, field_name)
    else
      get_field(changeset, field_name)
    end
  end

  def field_empty?(changeset, field_name) do
    field_missing?(changeset, field_name) || field_name in changeset.required
  end

  def add_timestamps(changeset) do
    changeset
    |> add_new_change(:inserted_at, DateTime.utc_now())
    |> add_new_change(:updated_at, DateTime.utc_now())
  end

  def add_new_change(changeset, field, value) do
    if changed?(changeset, field) do
      changeset
    else
      changeset |> cast(%{field => value}, [field])
    end
  end

  def stringify_value(attrs, key) do
    if Map.has_key?(attrs, key) do
      Map.put(attrs, key, "#{Map.get(attrs, key)}")
    else
      attrs
    end
  end

  def verify_required(struct, field) do
    if is_nil(struct) do
      {:error, not_found_error(field)}
    else
      {:ok, struct}
    end
  end

  def not_found_error(field \\ :id) do
    validation_message("does not exist", field, :not_found)
  end

  def validation_message(message, field \\ :id, code \\ :unknown) do
    %ValidationMessage{
      field: field,
      code: code,
      message: message,
      template: message
    }
  end

  def success(value), do: {:ok, value}
end
