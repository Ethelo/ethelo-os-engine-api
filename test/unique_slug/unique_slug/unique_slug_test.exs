defmodule UniqueSlugTest do
  @moduledoc """
  verify slugs are generated, checked and suffixed correctly
  """
  use UniqueSlug.UniqueSlugCase

  import UniqueSlug

  describe "internals" do

    test "slugify removes non alphanumeric" do
      assert string_to_slug(@invalid) == ""
    end

    test "chooses the first non empty string as a valid slug" do
      config = :full |> changeset() |> config()
      assert get_valid_source("good", nil, config) == "good"
      assert get_valid_source("good", "also good", config) == "good"
      assert get_valid_source(nil, "good", config) == "good"
      assert get_valid_source(@invalid, "good", config) == "good"
      assert {:error, _, []} = get_valid_source(nil, nil, config)
    end

    test "calls checker with value and changeset " do
      changeset = :full |> changeset() |> Ecto.Changeset.cast(%{id: "1a0"}, fields())
      checker = fn(value, changeset) -> value == "foo" && Ecto.Changeset.get_change(changeset, :id) == "1a0" end
      assert is_valid?("foo", config(changeset, checker)) == true
    end

    test "adds suffix to sequence if necessary" do
      config = :full |> changeset() |> config()
      assert generate_next_slug("foo bar", config) == {"foo-bar", 0}
      assert generate_next_slug({"foo bar", nil}, config) == {"foo-bar", 0}
      assert generate_next_slug({"foo bar", 7}, config) == {"foo-bar-8", 8}
    end
  end

  describe "noop" do

    test "when slug and source unchanged" do
      changeset = changeset(:full)
      result = changeset |> config() |> maybe_update_slug
      assert result == changeset
    end

    test "when slug exists and only source changes" do
      changeset = changeset(:source_changed)
      result = changeset |> config() |> maybe_update_slug
      assert result == changeset
    end

  end

  describe "raises" do

    test "error monad" do
      config = config(changeset(:source_changed), {:error, "nope"})
      assert_raise ArgumentError, ~r/nope/, fn -> maybe_update_slug(config) end
    end

    test "invalid slug field in args" do
      assert_raise ArgumentError, ~r/slug_field/, fn ->
        maybe_update_slug(changeset(:source_changed), "not an atom", :valid, checker())
      end
    end

    test "invalid source field in args" do
      assert_raise ArgumentError, ~r/source_field/, fn ->
        maybe_update_slug(changeset(:source_changed), :valid, "not an atom", checker())
      end
    end

    test "invalid checker in args" do
      assert_raise ArgumentError, ~r/checker/, fn ->
        maybe_update_slug(changeset(:source_changed), :valid, :valid, "not a function")
      end
    end

    test "invalid checker return" do
      config = Map.put(config(), :checker, checker(:error))
      assert_raise ArgumentError, ~r/checker/, fn ->
        maybe_update_slug(config)
      end
    end

    test "invalid checker return in monad" do
      config = Map.put(config(), :checker, checker({:ok, :error}))
      assert_raise ArgumentError, ~r/checker/, fn ->
        maybe_update_slug(config)
      end
    end

    test "invalid slug field in config" do
      config = Map.put(config(), :slug_field, 123)
      assert_raise ArgumentError, ~r/slug_field/, fn ->
        maybe_update_slug(config)
      end
    end

    test "invalid source field in config" do
      config = Map.put(config(), :source_field, 123)
      assert_raise ArgumentError, ~r/source_field/, fn ->
        maybe_update_slug(config)
      end
    end

    test "invalid checker in config" do
      config = Map.put(config(), :checker, "not a function")
      assert_raise ArgumentError, ~r/checker/, fn ->
        maybe_update_slug(config)
      end
    end
  end

  describe "generation without slug" do

    test "source only in base values" do
      changeset = changeset(%{source: "foo"}, %{})
      config = config(changeset)

      expected = Ecto.Changeset.put_change(changeset, :slug, "foo")
      assert maybe_update_slug(config) == expected
    end

    test "source only in updated values" do
      changeset = changeset(:empty, %{source: "foo"})
      config = config(changeset)

      expected = Ecto.Changeset.put_change(changeset, :slug, "foo")
      assert maybe_update_slug(config) == expected
    end

    test "updated source used when present in base and updated" do
      changeset = changeset(%{source: "boz"}, %{source: "foo"})
      config = config(changeset)

      expected = Ecto.Changeset.put_change(changeset, :slug, "foo")
      assert maybe_update_slug(config) == expected
    end

  end

  describe "generation without source" do

    test "slug supplied in base values" do
      changeset = changeset(%{slug: "foo"}, %{})
      config = config(changeset)

      expected = Ecto.Changeset.put_change(changeset, :slug, "foo")
      assert maybe_update_slug(config) == expected
    end

    test "slug supplied in updated values" do
      changeset = changeset(:empty, %{slug: "foo"})
      config = config(changeset)

      expected = Ecto.Changeset.put_change(changeset, :slug, "foo")
      assert maybe_update_slug(config) == expected
    end

    test "updated slug used when present in base and updated" do
      changeset = changeset(%{slug: "boz"}, %{slug: "foo"})
      config = config(changeset)

      expected = Ecto.Changeset.put_change(changeset, :slug, "foo")
      assert maybe_update_slug(config) == expected
    end

  end

  describe "generation with source and slug" do

    test "slug used when both supplied in base values" do
      changeset = changeset(%{slug: "foo", source: "bar"}, %{})
      config = config(changeset)

      expected = Ecto.Changeset.put_change(changeset, :slug, "foo")
      assert maybe_update_slug(config) == expected
    end

    test "slug used when both supplied in updated values" do
      changeset = changeset(:empty, %{slug: "foo", source: "bar"})
      config = config(changeset)

      expected = Ecto.Changeset.put_change(changeset, :slug, "foo")
      assert maybe_update_slug(config) == expected
    end

    test "updated slug used when both supplied in base and updated" do
      changeset = changeset(%{slug: "boz", source: "bar"}, %{slug: "foo", source: "baz"})
      config = config(changeset)

      expected = Ecto.Changeset.put_change(changeset, :slug, "foo")
      assert maybe_update_slug(config) == expected
    end

    test "source used when invalid slug in base values" do
      changeset = changeset(%{slug: @invalid}, %{source: "foo"})
      config = config(changeset)

      expected = Ecto.Changeset.put_change(changeset, :slug, "foo")
      assert maybe_update_slug(config) == expected
    end

    test "source used when invalid slug in updated values" do
      changeset = changeset(:empty, %{slug: @invalid, source: "foo"})
      config = config(changeset)

      expected = Ecto.Changeset.put_change(changeset, :slug, "foo")
      assert maybe_update_slug(config) == expected
    end

    test "updated source used when invalid slug in base and updated" do
      changeset = changeset(%{slug: @invalid, source: "bar"}, %{slug: @invalid, source: "foo"})
      config = config(changeset)

      expected = Ecto.Changeset.put_change(changeset, :slug, "foo")
      assert maybe_update_slug(config) == expected
    end

    test "succeeds after failing" do
      changeset = changeset(:empty, %{source: "foo"})
      checker = fn(value, _id) -> String.contains?(value, "4") end
      config = config(changeset, checker)

      expected = Ecto.Changeset.put_change(changeset, :slug, "foo-4")
      assert maybe_update_slug(config) == expected
    end

    test "succeeds after failing with monad" do
      changeset = changeset(:empty, %{source: "foo"})
      checker = fn(value, _id) -> {:ok, String.contains?(value, "4")} end
      config = config(changeset, checker)

      expected = Ecto.Changeset.put_change(changeset, :slug, "foo-4")
      assert maybe_update_slug(config) == expected
    end

  end

  describe "assigns error" do
    test "if source and slug values are both invalid" do
      changeset = changeset(:empty, %{source: @invalid, slug: @invalid})
      config = config(changeset)

      result = maybe_update_slug(config)
      assert "must have numbers and/or letters" in errors_on(result).slug
    end

    test "if updated source is invalid and slug is not present" do
      changeset = changeset(%{source: "foo"}, %{source: @invalid})
      config = config(changeset)

      result = maybe_update_slug(config)
      assert "must have numbers and/or letters" in errors_on(result).slug
    end

    test "if updated slug is invalid" do
      changeset = changeset(%{slug: "foo"}, %{slug: @invalid})
      config = config(changeset)

      result = maybe_update_slug(config)
      assert "must have numbers and/or letters" in errors_on(result).slug
    end

    test "after tries count exceeded" do
      changeset = changeset(%{slug: "foo"})
      config = config(changeset, false)

      result = maybe_update_slug(config)
      assert "cannot be generated (exceeded 10 variations)" in errors_on(result).slug
    end

    test "after tries count exceeded with monad" do
      changeset = changeset(%{slug: "foo"})
      config = config(changeset, {:ok, false})

      result = maybe_update_slug(config)
      assert "cannot be generated (exceeded 10 variations)" in errors_on(result).slug
    end

  end

  describe "applies configuration" do
    test "try count in args" do
      changeset = changeset(:source_changed)

      result = maybe_update_slug(changeset, :slug, :source, checker(false), [tries: 1])
      assert "cannot be generated (exceeded 1 variations)" in errors_on(result).slug
    end

    test "message in args" do
      changeset = changeset(:source_changed)

      result = maybe_update_slug(changeset, :slug, :source, checker(false), [message: "nope"])
      assert "nope" in errors_on(result).slug
    end

    test "message with substitutions in args" do
      changeset = changeset(:source_changed)

      result = maybe_update_slug(changeset, :slug, :source, checker(false), [message: "nope %{really}", message_opts: [really: "Really!"]])
      assert "nope Really!" in errors_on(result).slug
    end

    test "try count in config" do
      changeset = changeset(:source_changed)
      config = changeset |> config(false) |> Map.put(:tries, 1)

      result = maybe_update_slug(config)
      assert "cannot be generated (exceeded 1 variations)" in errors_on(result).slug
    end

    test "message in config" do
      changeset = changeset(:source_changed)
      config = changeset |> config(false) |> Map.put(:message, "nope")

      result = maybe_update_slug(config)
      assert "nope" in errors_on(result).slug
    end
  end
end
