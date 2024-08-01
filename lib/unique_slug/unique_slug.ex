defmodule UniqueSlug do
  @moduledoc """
  Updates a slug with sequential numbers if it already exists
  """
  import Ecto.Changeset

  @default_message "cannot be generated (exceeded %{variations} variations)"

  @enforce_keys [:slug_field, :source_field, :checker, :changeset]

  @type t :: %__MODULE__{
          slug_field: atom(),
          source_field: atom(),
          changeset: ChangeSet.t(),
          checker: fun(),
          slugger: fun(),
          message: String.t(),
          message_opts: [...],
          tries: integer()
        }

  defstruct slug_field: nil,
            source_field: nil,
            changeset: nil,
            checker: nil,
            slugger: nil,
            message: @default_message,
            message_opts: [],
            tries: 10

  @spec build_config(atom(), atom(), fun(), ChangeSet.t(), keyword) :: UniqueSlug.t()
  @doc """
  Generates a struct used by the slug routine
  """
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
    config = %UniqueSlug{
      slug_field: slug_field,
      source_field: source_field,
      checker: checker,
      changeset: changeset
    }

    config = %{config | tries: Keyword.get(opts, :tries, config.tries)}
    config = %{config | message: Keyword.get(opts, :message, config.message)}
    config = %{config | message_opts: Keyword.get(opts, :message_opts, config.message_opts)}
    config = %{config | slugger: Keyword.get(opts, :slugger, &string_to_slug/1)}
    config
  end

  @spec maybe_update_slug(Ecto.Changeset.t(), atom(), atom(), fun(), keyword) ::
          Ecto.Changeset.t()
  @doc """
  Apply submitted checker function to changeset to determine if a new slug needs to be generated
  Generates a new slug, adding a number to the end if necessary
  """
  def maybe_update_slug(
        %Ecto.Changeset{} = changeset,
        slug_field,
        source_field,
        checker,
        opts \\ []
      ) do
    config = build_config(slug_field, source_field, checker, changeset, opts)
    maybe_update_slug(config)
  end

  @spec maybe_update_slug(UniqueSlug.t()) :: Ecto.Changeset.t()
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
    slug_status = get_field_status(config.changeset, config.slug_field)
    source_status = get_field_status(config.changeset, config.source_field)

    case get_slug_value(slug_status, source_status, config) do
      nil ->
        config.changeset

      {:error, message, opts} ->
        add_error(
          config.changeset,
          config.slug_field,
          message,
          Enum.concat(opts, config.message_opts)
        )

      value ->
        put_change(config.changeset, config.slug_field, value)
    end
  end

  def get_field_status(%{errors: errors} = changeset, field) do
    errors = Enum.into(errors, %{})

    if Map.has_key?(errors, field) do
      :error
    else
      fetch_field(changeset, field)
    end
  end

  @spec get_slug_value(
          :error | {atom(), String.t() | nil},
          :error | {atom(), String.t() | nil},
          UniqueSlug.t()
        ) ::
          nil | String.t() | {:error, String.t(), keyword()}

  def get_slug_value({:data, nil}, {:data, nil}, _config),
    do: {:error, "must have numbers and/or letters", [code: :format]}

  # no changes to source or slug
  def get_slug_value({:data, _slug_val}, {:data, _source_val}, _config), do: nil

  def get_slug_value(slug_status, :error, config) do
    # if we have a slug, test it even if there's no source
    get_slug_value(slug_status, {:changes, nil}, config)
  end

  def get_slug_value(:error, source_status, config) do
    get_slug_value({:changes, nil}, source_status, config)
  end

  def get_slug_value({_, slug_val}, {_, source_val}, config) do
    {first_slug_base, _} = generate_next_slug(slug_val, config)
    {second_slug_base, _} = generate_next_slug(source_val, config)

    slug_base =
      case {first_slug_base, second_slug_base} do
        {slug, _} when byte_size(slug) > 0 -> first_slug_base
        {_, slug} when byte_size(slug) > 0 -> second_slug_base
        _ -> {:error, "must have numbers and/or letters", [code: :format]}
      end

    case slug_base do
      {:error, message, opts} -> {:error, message, opts}
      _ -> generate_and_check_slug({slug_base, nil}, config)
    end
  end

  @spec generate_and_check_slug({String.t(), integer() | nil}, UniqueSlug.t()) ::
          binary | {:error, String.t(), keyword()}
  def generate_and_check_slug({source, suffix}, %UniqueSlug{tries: tries, message: message})
      when is_integer(suffix) and suffix >= tries do
    {:error, message, [variations: tries, source: source, code: :generator]}
  end

  def generate_and_check_slug({value, _suffix} = to_generate, config) do
    {next_value, next_suffix} = generate_next_slug(to_generate, config)

    case is_valid?(next_value, config) do
      false ->
        generate_and_check_slug({value, next_suffix}, config)

      true ->
        next_value
    end
  end

  @spec is_valid?(String.t(), UniqueSlug.t()) :: boolean()
  @doc """
  Uses passed in checker to verify generated value
  """
  def is_valid?(value, %UniqueSlug{checker: checker, changeset: changeset})
      when is_function(checker) do
    case checker.(value, changeset) do
      {:ok, status} ->
        status

      {:error, message} ->
        raise ArgumentError, message: message

      false ->
        false

      true ->
        true

      unexpected ->
        raise ArgumentError, message: "unexpected return from checker #{inspect(unexpected)}"
    end
  end

  @spec generate_next_slug(
          String.t() | {String.t(), integer() | nil},
          UniqueSlug.t()
        ) :: {String.t(), integer}
  @doc """
  Regenerates slug with passed in suffix, returns new slug and incremented suffix
  """
  def generate_next_slug(value, config) when is_binary(value) do
    {config.slugger.(value), 0}
  end

  def generate_next_slug(nil, _), do: {"", nil}

  def generate_next_slug({value, nil}, config) do
    generate_next_slug(value, config)
  end

  def generate_next_slug({value, suffix}, config) when is_integer(suffix) do
    suffix = suffix + 1
    {next_value, _} = "#{value} #{suffix}" |> generate_next_slug(config)
    {next_value, suffix}
  end

  @spec string_to_slug(binary) :: binary
  @doc """
  Generic replacement to lowercase with no non-word values
  """
  def string_to_slug(value) do
    value
    |> String.downcase()
    |> String.trim()
    |> String.replace(~r/([^\w-])+/u, "-")
    |> String.trim("-")
  end

  @spec valid_slug_source?(String.t(), UniqueSlug.t()) :: boolean()
  def valid_slug_source?(value, config) when is_binary(value) do
    {slug, _} = generate_next_slug(value, config)
    slug != ""
  end

  def valid_slug_source?(_value, _config), do: false
end
