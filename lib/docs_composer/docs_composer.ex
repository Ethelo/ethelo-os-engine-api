defmodule DocsComposer do
  @moduledoc """
  methods for assembling documentation from configured strings
  """
  require Inflex

  defmacro __using__(module: doc_module) do
    quote do
      docs = unquote(doc_module)
      defdelegate fields, to: docs, as: :fields
      defdelegate examples, to: docs, as: :examples
      defdelegate strings, to: docs, as: :strings

      @doc_map %{
        strings: docs.strings(),
        fields: docs.fields(),
        examples: docs.examples()
      }

      import DocsComposer
    end
  end

  alias DocsComposer.Common

  @doc """
  A map with simple descriptions for common fields.

  - *id*: Unique identifier
  - *slug*: A memorable and communicatable id. Suitable for use in a url. Will be generated automatically from title if empty or not supplied.
  - *inserted_at*: Date/time item was created. Automatically updated
  - *updated_at*: Date/time item was last updated. Automatically updated.
  """
  defdelegate common_strings(), to: Common, as: :strings

  @doc """
  Given a list of field definitions, assemble a string with a markdown table of the options

  Accepts either a list of fields, or a map with a `:fields` key containing a list of fields.
  Each field must be a map with keys for `:name`, `:type`, `:info`, `:required`, `:automatic`, `:immutable`.
  Missing fields generate empty table cells. Extra fields are not included.

  Definitions for common fields are available through `common_fields/0`
  """
  defdelegate schema_fields(doc_strings), to: DocsComposer.FieldTableBuilder, as: :to_markdown

  @doc """
  Given a map of key-value pairs, assemble a string with them separated by commas, such as in a graphql query
  """
  defdelegate schema_examples(examples), to: DocsComposer.MarkdownBuilder

  @doc """
  Provides a list of definitions for common fields

  - *id*: id, required, automatic, immutable
  - *title*: string, required
  - *slug*: string, automatic(from slug)
  - *inserted_at*: datetime, automatic, immutable
  - *updated_at*: datetime, automatic, immutable

  By default the entire list is returned. Passing in a list of atom keys will limit the list to only the provided fields.
  """
  defdelegate common_fields(), to: Common, as: :fields
  defdelegate common_fields(only), to: Common, as: :fields
end
