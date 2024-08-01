defmodule DocsComposer.ComposerTest do
  @moduledoc """
  Test methods used to generate documentation
  """

  use ExUnit.Case
  require Earmark
  require DocsComposer

  def assert_valid_markdown(content) do
    assert {:ok, _, _} = Earmark.as_html(content)
  end

  describe "examples" do
    def example(), do: %{one_thing: 12, two: "two words", three: :an_atom}

    test "formats mulitple examples" do
      examples = %{"first" => example(), "second" => example()}
      content = DocsComposer.schema_examples(examples)

      expected_strings = ["### first", "### second"]

      for expected <- expected_strings do
        assert content =~ ~r/#{expected}/
      end

      expected_twice = ["one_thing: 12", "two: two words", "three: an_atom"]

      for expected <- expected_twice do
        assert content =~ ~r/#{expected}.* second.* #{expected}/s
      end

      assert_valid_markdown(content)
    end

    test "formats a single example" do
      content = DocsComposer.MarkdownBuilder.format_example({"sample", example()})
      expected_strings = ["### sample", "one_thing: 12", "two: two words", "three: an_atom"]

      for expected <- expected_strings do
        assert content =~ ~r/#{expected}/
      end

      assert_valid_markdown(content)
    end
  end

  describe "common fields" do
    test " have all possible fields" do
      fields = DocsComposer.common_fields()
      assert is_list(fields)

      for field <- fields do
        assert %{
                 name: _,
                 info: _,
                 type: _,
                 required: _,
                 automatic: _,
                 immutable: _,
                 validation: _
               } = field
      end
    end

    test "returns only requested" do
      assert [id_field] = DocsComposer.common_fields([:id])
      assert %{name: :id} = id_field
    end
  end

  describe "schema fields" do
    def assert_cells_match(content, expected, line) do
      lines = String.split(content, "\n")
      assert Enum.count(lines) >= line
      field_line = Enum.at(lines, line)
      cells = String.split(field_line, "|")
      assert cells == expected
    end

    def complete_field() do
      %{
        name: :first,
        info: String.duplicate("words ", 5),
        type: "Type",
        required: nil,
        automatic: true,
        immutable: true
      }
    end

    def complete_field_cells() do
      [
        "",
        " first ",
        " Type ",
        " words words words words words  Updated Automatically. Immutable. ",
        "  ",
        ""
      ]
    end

    def partial_field() do
      %{name: :second, required: true, immutable: false, automatic: "something custom"}
    end

    def partial_field_cells() do
      ["", " second ", "  ", " something custom ", " Required. ", ""]
    end

    test "raises on non list" do
      assert_raise ArgumentError, fn -> DocsComposer.schema_fields("invalid content") end
    end

    test "fills in missing values" do
      content = DocsComposer.schema_fields([partial_field()])
      assert assert_cells_match(content, partial_field_cells(), 3)
      assert_valid_markdown(content)
    end

    test "builds from field list" do
      content = DocsComposer.schema_fields([complete_field()])
      assert assert_cells_match(content, complete_field_cells(), 3)
      assert_valid_markdown(content)
    end

    test "builds multiple fields" do
      content = DocsComposer.schema_fields([complete_field(), partial_field()])
      assert assert_cells_match(content, complete_field_cells(), 3)
      assert assert_cells_match(content, partial_field_cells(), 4)
      assert_valid_markdown(content)
    end
  end

  describe "macro" do
    defmodule CommonTest do
      @moduledoc false
      use DocsComposer, module: DocsComposer.Common
    end

    test "delegated fields work" do
      assert is_list(CommonTest.fields())
      assert is_map(CommonTest.examples())
      assert is_map(CommonTest.strings())
    end
  end
end
