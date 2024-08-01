defmodule UniqueSlugTest do
  @moduledoc """
  verify slugs are generated, checked and suffixed correctly
  """
  use ExUnit.Case
  @moduletag unique_slug: true, ecto: true

  import UniqueSlug

  @invalid "~!@#$% ^&*\(\)+`-=\[\{\}\]\|\\;':\" "

  @doc """
  A helper that transform changeset errors to a map of messages.

      assert "password is too short" in error_map(changeset).password
      assert %{password: ["password is too short"]} = error_map(changeset)

  """
  def error_map(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  def config(%Ecto.Changeset{} = changeset), do: config(changeset, checker_function())

  def config(%Ecto.Changeset{} = changeset, checker) when is_function(checker) do
    %UniqueSlug{
      source_field: :source,
      slug_field: :slug,
      checker: checker,
      changeset: changeset,
      slugger: &UniqueSlug.string_to_slug/1
    }
  end

  def changeset(%{} = base, %{} = updates) do
    {base, types()} |> Ecto.Changeset.cast(updates, fields())
  end

  def base_changeset(%{} = updates \\ %{}) do
    changeset(%{source: "bar", slug: "bar"}, updates)
  end

  def default_config() do
    %UniqueSlug{
      source_field: :source,
      slug_field: :slug,
      checker: checker_function(),
      changeset: base_changeset(),
      slugger: &UniqueSlug.string_to_slug/1
    }
  end

  def checker_function(value \\ true)
  def checker_function(function) when is_function(function), do: function
  def checker_function(value), do: fn _value, _id -> value end

  def types(), do: %{source: :string, slug: :string, id: :string}
  def fields(), do: Map.keys(types())

  describe "internals" do
    test "slugify removes non alphanumeric" do
      assert string_to_slug(@invalid) == ""
    end

    test "calls checker with value and changeset" do
      changeset =
        base_changeset()
        |> Ecto.Changeset.cast(%{id: "1a0"}, fields())

      checker = fn value, changeset ->
        value == "foo" && Ecto.Changeset.get_change(changeset, :id) == "1a0"
      end

      assert is_valid?("foo", config(changeset, checker)) == true
    end

    test "adds suffix to sequence if necessary" do
      config = default_config()
      assert generate_next_slug("foo bar", config) == {"foo-bar", 0}
      assert generate_next_slug({"foo bar", nil}, config) == {"foo-bar", 0}
      assert generate_next_slug({"foo bar", 7}, config) == {"foo-bar-8", 8}
    end
  end

  describe "noop" do
    test "when slug and source unchanged" do
      config = default_config()
      result = maybe_update_slug(config)
      assert result == config.changeset
    end

    test "when slug exists and only source changes" do
      changeset = base_changeset(%{source: "foo"})
      result = changeset |> config() |> maybe_update_slug
      assert result == changeset
    end
  end

  describe "raises" do
    test "error monad" do
      changeset = base_changeset(%{source: "foo"})
      checker = checker_function({:error, "nope"})
      config = config(changeset, checker)
      assert_raise ArgumentError, ~r/nope/, fn -> maybe_update_slug(config) end
    end

    test "invalid slug field in config" do
      changeset = base_changeset(%{source: "foo"})

      config =
        config(changeset)
        |> Map.put(:slug_field, "slug")

      assert_raise ArgumentError, ~r/slug_field/, fn ->
        maybe_update_slug(config)
      end
    end

    test "invalid source field in config" do
      changeset = base_changeset(%{source: "foo"})

      config =
        config(changeset)
        |> Map.put(:source_field, "source")

      assert_raise ArgumentError, ~r/source_field/, fn ->
        maybe_update_slug(config)
      end
    end

    test "invalid checker in config" do
      config = Map.put(default_config(), :checker, "not a function")

      assert_raise ArgumentError, ~r/checker/, fn ->
        maybe_update_slug(config)
      end
    end
  end

  describe "creates from slug" do
    test "when slug only in base " do
      changeset = changeset(%{slug: "foo"}, %{})
      config = config(changeset)

      expected = Ecto.Changeset.put_change(changeset, :slug, "foo")
      assert maybe_update_slug(config) == expected
    end

    test "when slug only in updates" do
      changeset = changeset(%{}, %{slug: "foo"})
      config = config(changeset)

      expected = Ecto.Changeset.put_change(changeset, :slug, "foo")
      assert maybe_update_slug(config) == expected
    end

    test "using updated when present in base and updated" do
      changeset = changeset(%{slug: "boz"}, %{slug: "foo"})
      config = config(changeset)

      expected = Ecto.Changeset.put_change(changeset, :slug, "foo")
      assert maybe_update_slug(config) == expected
    end

    test "using base slug when base source also present " do
      changeset = changeset(%{slug: "foo", source: "bar"}, %{})
      config = config(changeset)

      expected = Ecto.Changeset.put_change(changeset, :slug, "foo")
      assert maybe_update_slug(config) == expected
    end

    test "using updated slug when updated source also present" do
      changeset = changeset(%{}, %{slug: "foo", source: "bar"})
      config = config(changeset)

      expected = Ecto.Changeset.put_change(changeset, :slug, "foo")
      assert maybe_update_slug(config) == expected
    end

    test "using updated slug when all base and updated fields present" do
      changeset = changeset(%{slug: "boz", source: "bar"}, %{slug: "foo", source: "baz"})
      config = config(changeset)

      expected = Ecto.Changeset.put_change(changeset, :slug, "foo")
      assert maybe_update_slug(config) == expected
    end
  end

  describe "creates from source" do
    test "when only base source" do
      changeset = changeset(%{source: "foo"}, %{})
      config = config(changeset)

      expected = Ecto.Changeset.put_change(changeset, :slug, "foo")
      assert maybe_update_slug(config) == expected
    end

    test "when only updated source" do
      changeset = changeset(%{}, %{source: "foo"})
      config = config(changeset)

      expected = Ecto.Changeset.put_change(changeset, :slug, "foo")
      assert maybe_update_slug(config) == expected
    end

    test "using updated source when both available " do
      changeset = changeset(%{source: "boz"}, %{source: "foo"})
      config = config(changeset)

      expected = Ecto.Changeset.put_change(changeset, :slug, "foo")
      assert maybe_update_slug(config) == expected
    end

    test "using updated source when base slug is invalid" do
      changeset = changeset(%{slug: @invalid}, %{source: "foo"})
      config = config(changeset)

      expected = Ecto.Changeset.put_change(changeset, :slug, "foo")
      assert maybe_update_slug(config) == expected
    end

    test "using updated source when updated slug is invalid" do
      changeset = changeset(%{}, %{slug: @invalid, source: "foo"})
      config = config(changeset)

      expected = Ecto.Changeset.put_change(changeset, :slug, "foo")
      assert maybe_update_slug(config) == expected
    end

    test "using updated source used when base and updated slugs are invalid" do
      changeset = changeset(%{slug: @invalid, source: "bar"}, %{slug: @invalid, source: "foo"})
      config = config(changeset)

      expected = Ecto.Changeset.put_change(changeset, :slug, "foo")
      assert maybe_update_slug(config) == expected
    end
  end

  describe "retries" do
    test "succeeds after failing" do
      changeset = changeset(%{}, %{source: "foo"})
      checker = fn value, _id -> String.contains?(value, "4") end
      config = config(changeset, checker)

      expected = Ecto.Changeset.put_change(changeset, :slug, "foo-4")
      assert maybe_update_slug(config) == expected
    end

    test "succeeds after failing with monad" do
      changeset = changeset(%{}, %{source: "foo"})
      checker = fn value, _id -> {:ok, String.contains?(value, "4")} end
      config = config(changeset, checker)

      expected = Ecto.Changeset.put_change(changeset, :slug, "foo-4")
      assert maybe_update_slug(config) == expected
    end
  end

  describe "assigns error" do
    test "if source and slug values are both invalid" do
      changeset = changeset(%{}, %{source: @invalid, slug: @invalid})
      config = config(changeset)

      result = maybe_update_slug(config)
      assert "must have numbers and/or letters" in error_map(result).slug
    end

    test "if updated source is invalid and slug is not present" do
      changeset = changeset(%{source: "foo"}, %{source: @invalid})
      config = config(changeset)

      result = maybe_update_slug(config)
      assert "must have numbers and/or letters" in error_map(result).slug
    end

    test "if source has error and slug is not present" do
      changeset = changeset(%{source: "foo"}, %{}) |> Ecto.Changeset.add_error(:source, "invalid")
      config = config(changeset)

      result = maybe_update_slug(config)
      assert "must have numbers and/or letters" in error_map(result).slug
    end

    test "if updated slug is invalid" do
      changeset = changeset(%{slug: "foo"}, %{slug: @invalid})
      config = config(changeset)

      result = maybe_update_slug(config)
      assert "must have numbers and/or letters" in error_map(result).slug
    end

    test "after tries count exceeded" do
      changeset = base_changeset(%{slug: "foo"})
      checker = checker_function(false)

      config = config(changeset, checker)

      result = maybe_update_slug(config)
      assert "cannot be generated (exceeded 10 variations)" in error_map(result).slug
    end

    test "after tries count exceeded with monad" do
      changeset = base_changeset(%{slug: "foo"})
      checker = checker_function({:ok, false})
      config = config(changeset, checker)

      result = maybe_update_slug(config)
      assert "cannot be generated (exceeded 10 variations)" in error_map(result).slug
    end
  end

  describe "applies configuration" do
    test "try count in args" do
      changeset = base_changeset(%{source: "foo"})

      result = maybe_update_slug(changeset, :slug, :source, checker_function(false), tries: 1)
      assert "cannot be generated (exceeded 1 variations)" in error_map(result).slug
    end

    test "message in args" do
      changeset = base_changeset(%{source: "foo"})

      result =
        maybe_update_slug(changeset, :slug, :source, checker_function(false), message: "nope")

      assert "nope" in error_map(result).slug
    end

    test "message with substitutions in args" do
      changeset = base_changeset(%{source: "foo"})

      result =
        maybe_update_slug(changeset, :slug, :source, checker_function(false),
          message: "nope %{really}",
          message_opts: [really: "Really!"]
        )

      assert "nope Really!" in error_map(result).slug
    end

    test "try count in config" do
      changeset = base_changeset(%{source: "foo"})
      checker = checker_function(false)
      config = config(changeset, checker) |> Map.put(:tries, 1)

      result = maybe_update_slug(config)
      assert "cannot be generated (exceeded 1 variations)" in error_map(result).slug
    end

    test "message in config" do
      changeset = base_changeset(%{source: "foo"})
      checker = checker_function(false)
      config = config(changeset, checker) |> Map.put(:message, "nope")

      result = maybe_update_slug(config)
      assert "nope" in error_map(result).slug
    end
  end
end
