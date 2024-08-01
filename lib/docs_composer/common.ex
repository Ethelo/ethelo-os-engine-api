defmodule DocsComposer.Common do
  @moduledoc """
  Common field definitions and descriptions
  """

  @doc """
  A map of strings describing id, slug, inserted_at, and updated_at
  """
  def strings() do
    %{
      id: "Unique identifier.",
      slug:
        "A memorable and communicatable id. Suitable for use in a url. Will be generated automatically from title if empty or not supplied.",
      inserted_at: "Date/time item was created.",
      updated_at: "Date/time item was last updated.",
      decision_id: "The Decision the record belongs to.",
      deleted: "Object is flagged to delete on publish (soft delete)",
      sort: "The sort order for display"
    }
  end

  @doc """
  Map describing example records with common fields

  Suitable for use with `DocsComposer.schema_examples`.
  """
  def examples() do
    %{
      "": %{
        "id" => 1,
        "decision_id" => 1,
        "slug" => "my-project",
        "deleted" => false,
        "inserted_at" => "2017-05-05T16:48:16+00:00",
        "updated_at" => "2017-05-05T16:48:16+00:00",
        "sort" => 1
      }
    }
  end

  defp field_definitions() do
    strings = strings()

    %{
      id: %{
        name: :id,
        info: strings.id,
        type: :id,
        required: false,
        automatic: true,
        immutable: true,
        validation: "N/A"
      },
      slug: %{
        name: :slug,
        info: strings.slug,
        type: :string,
        required: true,
        automatic: true,
        immutable: false,
        validation: "must be unique"
      },
      deleted: %{
        name: :deleted,
        info: strings.deleted,
        type: :boolean,
        required: true,
        automatic: true,
        immutable: false,
        validation: "N/A"
      },
      inserted_at: %{
        name: :inserted_at,
        info: strings.inserted_at,
        type: :datetime,
        required: false,
        automatic: true,
        immutable: true,
        validation: "N/A"
      },
      updated_at: %{
        name: :updated_at,
        info: strings.updated_at,
        type: :datetime,
        required: false,
        automatic: true,
        immutable: true,
        validation: "N/A"
      },
      decision_id: %{
        name: :decision_id,
        info: strings.decision_id,
        type: "id",
        required: true,
        immutable: true,
        automatic: false,
        validation: "must be an existing Decision"
      },
      sort: %{
        name: :sort,
        info: strings.sort,
        type: :integer,
        required: false,
        automatic: true,
        immutable: false,
        validation: "N/A"
      }
    }
  end

  @doc """
  maps describing id, slug, deleted inserted_at, and updated_at fields.

  Maps are suitable for use with `DocsComposer.schema_fields/1`.
  """
  def fields(), do: Map.values(field_definitions())

  @doc """
  maps describing id, slug, inserted_at, and updated_at fields.

  Maps are suitable for use with `DocsComposer.schema_fields/1`. Only returns specified fields.
  """
  def fields(only) when is_list(only) do
    field_definitions() |> Map.take(only) |> Map.values()
  end
end
