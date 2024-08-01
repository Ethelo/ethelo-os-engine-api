defmodule UniqueSlug do
  @moduledoc """
  Updates a slug with sequential numbers if it already exists
  """
  import Ecto.Changeset

  @default_message "cannot be generated (exceeded %{variations} variations)"

  @enforce_keys [:slug_field, :source_field, :checker, :changeset]
  defstruct [
    slug_field: nil, source_field: nil, changeset: nil,
    checker: nil, slugger: nil,
    message: @default_message, message_opts: [],
    tries: 10]

  def build_config(slug_field, source_field, checker, changeset, opts \\ [])
  def build_config(slug_field, _, _, _, _) when not is_atom(slug_field) do
    raise ArgumentError, message: "invalid config for slug_field"
  end

  def build_config(_, source_field, _, _, _) when not is_atom(source_field) do
    raise ArgumentError, message: "invalid config for source_field"
  end

  def build_config(_, _, checker, _, _) when not is_function(checker) do
    raise ArgumentError, message: "checker must be a function"
  end

  def build_config(slug_field, source_field, checker, changeset, opts) do
    config = %UniqueSlug{slug_field: slug_field, source_field: source_field, checker: checker, changeset: changeset}
    config = %{config | tries: Keyword.get(opts, :tries, config.tries)}
    config = %{config | message: Keyword.get(opts, :message, config.message)}
    config = %{config | message_opts: Keyword.get(opts, :message_opts, config.message_opts)}
    config = %{config | slugger: Keyword.get(opts, :slugger, &string_to_slug/1)}
    config
  end

  def maybe_update_slug(%Ecto.Changeset{} = changeset, slug_field, source_field, checker, opts \\ []) do
    config = build_config(slug_field, source_field, checker, changeset, opts)
    maybe_update_slug(config)
  end

  def maybe_update_slug(%UniqueSlug{slug_field: slug_field}) when not is_atom(slug_field) do
    raise ArgumentError, message: "invalid config for slug_field"
  end

  def maybe_update_slug(%UniqueSlug{source_field: source_field}) when not is_atom(source_field) do
    raise ArgumentError, message: "invalid config for source_field"
  end

  def maybe_update_slug(%UniqueSlug{checker: checker}) when not is_function(checker) do
    raise ArgumentError, message: "checker must be a function"
  end

  def maybe_update_slug(%UniqueSlug{slugger: slugger}) when not is_function(slugger) do
    raise ArgumentError, message: "slugger must be a function"
  end

  def maybe_update_slug(%UniqueSlug{} = config) do
    slug_status = fetch_field(config.changeset, config.slug_field)
    source_status = fetch_field(config.changeset, config.source_field)

    case get_slug_value(slug_status, source_status, config) do
      nil -> config.changeset
      {:error, message, opts} -> add_error(config.changeset, config.slug_field, message, Enum.concat(opts, config.message_opts))
      value -> put_change(config.changeset, config.slug_field, value)
    end
  end

  def get_valid_source(first_choice, second_choice \\ nil, %UniqueSlug{} = config) do
    cond do
      valid_slug_source?(first_choice, config) -> first_choice
      valid_slug_source?(second_choice, config) -> second_choice
      true -> {:error, "must have numbers and/or letters", []}
    end
  end

  #no source or slug value, cannot generate slug
  def get_slug_value(:error, :error, _config), do: nil

  def get_slug_value(slug_status, :error,  config) do
    # if we have a slug, test it even if there's no source
    get_slug_value(slug_status, {:change, nil}, config)
  end

  def get_slug_value(:error, source_status, config) do #no existing value
    get_slug_value({:change, nil}, source_status, config)
  end

  def get_slug_value({:data, nil}, source_status, config) do
    get_slug_value({:change, nil}, source_status, config)
  end

  # no changes to source or slug
  def get_slug_value({:data, _slug_val}, {:data, _source_val}, _config), do: nil

  # don't regenerate automatically, if regeneration is desired, it'll be set to nil
  def get_slug_value({_, slug_val}, {_, source_val}, config) do
    case get_valid_source(slug_val, source_val, config) do
      {:error, message, opts} -> {:error, message, opts}
      {:error, message} -> {:error, message, []}
      source -> generate_and_check_slug({source, nil}, config)
    end
  end

  def generate_and_check_slug({source, suffix}, %UniqueSlug{tries: tries, message: message}) when is_integer(suffix) and suffix >= tries do
    {:error, message, [variations: tries, source: source] }
  end

  def generate_and_check_slug({value, _suffix} = to_generate, config) do
    {next_value, next_suffix} = generate_next_slug(to_generate, config)
    case is_valid?(next_value, config) do
      false -> generate_and_check_slug({value, next_suffix}, config)
      true -> next_value
      unexpected -> raise ArgumentError, message: "unexpected return from checker #{inspect(unexpected)}"
    end
  end

  def is_valid?(value, %UniqueSlug{checker: checker, changeset: changeset}) when is_function(checker) do
    case checker.(value, changeset) do
      {:ok, status} -> status
      {:error, message} -> raise ArgumentError, message: message
      false -> false
      true -> true
      unexpected -> raise ArgumentError, message: "unexpected return from checker #{inspect(unexpected)}"
    end
  end

  def generate_next_slug(value, config) when is_binary(value) do
    {config.slugger.(value), 0}
  end

  def generate_next_slug({value, nil}, config) do
    value |> generate_next_slug(config)
  end

  def generate_next_slug({value, suffix}, config) when is_integer(suffix) do
    suffix = suffix + 1
    {next_value, _} = value |> append_suffix(suffix) |> generate_next_slug(config)
    {next_value, suffix}
  end

  def append_suffix(value, suffix) do
    "#{value} #{suffix}"
  end

  def string_to_slug(value) do
    value
    |> String.downcase()
    |> String.trim()
    |> String.replace(~r/([^\w-]|_)+/u, "-")
    |> String.trim("-")
  end

  def valid_slug_source?(value, config) when is_binary(value) do
    {slug, _} = generate_next_slug(value, config)
    slug != ""
  end

  def valid_slug_source?(_value, _config), do: false

end
