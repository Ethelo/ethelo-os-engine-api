defmodule EtheloApi.Structure.Docs.Decision do
  @moduledoc "Central repository for documentation strings about Decisions."

  require DocsComposer

  @decision """
  Decisions are core to EtheloApi. This is the starting point for all the Options, Constraints and other data used in the process.

  At its simplest, a Decision is about choosing from a list of Options.
  """

  @info "Informative text describing the Decision."
  @title "Name of Decision. Used to generate slug if none supplied"
  @copyable "Indicates if Decision is a base template used for copying"
  @internal "Indicates if Decision is a special use template used for page templates"
  @max_users "Maximum users that can join a Decision"
  @language "The language to display to Participants"
  @keywords "Keywords assigned to Decision by staff"

  defp decision_fields() do
    [
      %{
        name: :info,
        info: @info,
        type: "markdown",
        required: false,
        automatic: false,
        immutable: false
      },
      %{
        name: :title,
        info: @title,
        type: :string,
        validation: "Must include at least one word",
        required: true,
        automatic: false,
        immutable: false
      },
      %{
        name: :keywords,
        info: @keywords,
        type: "array[:string]",
        required: false,
        automatic: false,
        immutable: false
      },
      %{
        name: :language,
        info: @language,
        type: :string,
        validation: "Must be a valid language",
        immutable: false
      },
      %{
        name: :internal,
        info: @internal,
        type: :boolean,
        default: false,
        automatic: true,
        immutable: false
      },
      %{
        name: :copyable,
        info: @copyable,
        type: :boolean,
        default: false,
        automatic: true,
        immutable: false
      },
      %{
        name: :max_users,
        info: @max_users,
        type: :integer,
        default: 20,
        automatic: true,
        immutable: false
      }
    ]
  end

  @doc """
  a list of maps describing all Decision schema fields

  Suitable for use with `DocsComposer.schema_fields`.
  """
  def fields() do
    DocsComposer.common_fields([:id, :slug, :inserted_at, :updated_at]) ++ decision_fields()
  end

  @doc """
  Map describing example records

  Suitable for use with `DocsComposer.schema_examples`.
  """
  def examples() do
    %{
      "Sample 1" => %{
        id: 1,
        info: "There can be only one true pizza. Choose wisely.",
        slug: "pizza-chooser",
        title: "Pizza Chooser Extraordinaire",
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T16:48:16+00:00",
        copyable: false,
        internal: false,
        language: "en",
        max_users: 10,
        keywords: ["a", "b", "12"]
      },
      "Sample 2" => %{
        id: 2,
        info: "Demo of some kind",
        slug: "my-demo",
        title: "My Demo",
        inserted_at: "2017-05-08T16:48:16+00:00",
        updated_at: "2017-05-08T16:48:16+00:00",
        internal: false,
        copyable: false,
        language: "en",
        max_users: 15,
        keywords: ["d", "e", "2"]
      },
      "Update 1" => %{
        id: 1,
        info: "There can only be one. Choose wisely.",
        slug: "pizza-chooser-app",
        title: "Pizza Chooser",
        inserted_at: "2017-05-05T16:48:16+00:00",
        updated_at: "2017-05-05T17:42:36+00:00",
        copyable: true,
        internal: true,
        language: "en",
        max_users: 20,
        keywords: ["f", "g", "22"]
      }
    }
  end

  @doc """
  strings describing each field as well as the general concept of "Decisions"
  """
  def strings() do
    decision_strings = %{
      decision: @decision,
      info: @info,
      title: @title,
      copyable: @copyable,
      internal: @internal,
      language: @language,
      keywords: @keywords,
      max_users: @max_users
    }

    DocsComposer.common_strings() |> Map.merge(decision_strings)
  end
end
