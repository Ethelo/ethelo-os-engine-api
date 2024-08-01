defmodule EtheloApi.Helpers.ValidationHelper do
  @moduledoc """
  Helper Methods for records associated with Decisions
  """

  alias EtheloApi.Repo
  import Ecto.Changeset

  @doc "quick helper to see if a field has an error"
  def has_error?(changeset, field_name) do
    !is_nil(changeset.errors[field_name])
  end

  @doc "helper to allow empty strings as field values

  must be called BEFORE cast to have any effect.
  "
  def allow_empty_strings(%Ecto.Changeset{valid?: false}) do
    raise ArgumentError, "Cannot allow empty strings on a Changeset after cast has been called"
  end
  def allow_empty_strings(%Ecto.Changeset{changes: %{}} = changeset) do
    Map.put(changeset, :empty_values, [])
  end
  def allow_empty_strings(_changeset) do
    raise ArgumentError, "Cannot allow empty strings on a Changeset after cast has been called"
  end

  @doc """
  verifies that association exists in decision

  first checks that id is passed in, then tries to load the object.
  if loaded value is nil or "". adds a foreign_key_constraint error

  """
  def validate_assoc_in_decision(changeset, decision, key_field, assoc_module) do
    id_value = get_field(changeset, key_field)

    if id_value in [nil, ""] do
      changeset = validate_required(changeset, key_field)
      {changeset, nil, nil}
    else
      object = Repo.get_by(assoc_module, %{decision_id: decision.id, id: id_value})

      changeset = changeset
      |> validate_foreign_presence(key_field, object)
      |> foreign_key_constraint(key_field)

      {changeset, object, id_value}
    end
  end

  def validate_optional_assoc_in_decision(changeset, decision, key_field, assoc_module) do
    id_value = get_field(changeset, key_field)

    if id_value in [nil, ""] do
      {changeset, nil, nil}
    else
      object = Repo.get_by(assoc_module, %{decision_id: decision.id, id: id_value})

      changeset = changeset
      |> validate_foreign_presence(key_field, object)
      |> foreign_key_constraint(key_field)

      {changeset, object, id_value}
    end
  end

  def validate_foreign_presence(changeset, field_name, nil) do
    add_foreign_error(changeset, field_name)
  end

  def validate_foreign_presence(changeset, _field_name, _truthy) do
    changeset
  end

  defp add_foreign_error(changeset, field_name) do
    add_error(changeset, field_name, "does not exist", [code: :foreign])
  end

  @doc "require a field to be nil or \"\""
  def validate_empty(changeset, field_name, message) do
    field_value = get_field(changeset, field_name)
    if field_value in [nil, ""] do
      changeset
    else
      add_error(changeset, field_name, message, code: :empty)
    end
  end

  def stringify_value(attrs, key) do
    if Map.has_key?(attrs, key) do
      Map.put(attrs, key, "#{Map.get(attrs, key)}")
    else
      attrs
    end
  end

  def protected_record_changeset(schema, field_name, message \\ "cannot be deleted") do
    schema
    |> Kernel.struct()
    |> Ecto.Changeset.change()
    |> add_error(field_name, message, [code: :protected_record])
  end

  def unicode_word_check_regex(), do: ~r/[[:alnum:]]/u
end
