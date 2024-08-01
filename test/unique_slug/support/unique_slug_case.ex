defmodule UniqueSlug.UniqueSlugCase do
  @moduledoc """
  This module defines the setup for tests for the slugger

  You may define functions here to be used as helpers in
  your tests.
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      import Ecto.Changeset
      import UniqueSlug.UniqueSlugCase

      @invalid invalid()
      @types types()

    end
  end

  def invalid(), do:  "~!@#$% ^&*\(\)_+`-=\[\{\}\]\|\\;':\" "  #no word characters
  def types(), do: %{source: :string, slug: :string, id: :string}  #no word characters
  def fields(), do: Map.keys(types())

  @doc """
  A helper that transform changeset errors to a map of messages.
  Note: Copied from Phoenix data case

      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  def cast_schemaless(config, attrs) do
    config |> Ecto.Changeset.cast(attrs, fields())
  end

  def changeset(base, updates \\ %{})
  def changeset(:source_changed, _) do
    {%{source: "bar", slug: "bar"}, types()} |> cast_schemaless(%{source: "foo"})
  end
  def changeset(:slug_changed, _) do
    {%{source: "bar", slug: "bar"}, types()} |> cast_schemaless(%{slug: "foo"})
  end
  def changeset(:empty, %{} = updates) do
    {%{}, types()} |> cast_schemaless(updates)
  end
  def changeset(:full, %{} = updates) do
    {%{source: "foo", slug: "foo"}, types()} |> cast_schemaless(updates)
  end
  def changeset(%{} = base, %{} = updates) do
    {base, types()} |> cast_schemaless(updates)
  end

  def checker(value \\ true)
  def checker(function) when is_function(function), do: function
  def checker(value), do: fn(_value, _id) -> value end

  def config(), do: config(changeset(:source_changed), checker())
  def config(function) when is_function(function), do: config(changeset(:source_changed), function)
  def config(%Ecto.Changeset{} = changeset), do: config(changeset, checker())
  def config(return_value), do: config(changeset(:source_changed), checker(return_value))

  def config(changeset, return_value) when not is_function(return_value) do
     config(changeset, checker(return_value))
  end

  def config(%Ecto.Changeset{} = changeset, checker) when is_function(checker) do
    %UniqueSlug{source_field: :source, slug_field: :slug, checker: checker, changeset: changeset, slugger: &UniqueSlug.string_to_slug/1}
  end

end
