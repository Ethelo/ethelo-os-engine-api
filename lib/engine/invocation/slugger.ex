defmodule Engine.Invocation.Slugger do
  @moduledoc """
  shared methods to ensure consistent naming for detail and filter values
  """

  alias EtheloApi.Structure.Variable

  def detail_value_slug(%{slug: slug}), do: slug(slug, "D")
  def detail_value_slug(value) when is_binary(value), do: slug(value, "D")

  def filter_group_slug(%{slug: slug}), do: slug(slug, "G")
  def filter_group_slug(value) when is_atom(value), do: Atom.to_string(value) |> slug("G")
  def filter_group_slug(value) when is_binary(value), do: slug(value, "G")

  def slug(slug, prefix) do
    "#{prefix}#{Variable.slugger(slug)}"
  end

end
