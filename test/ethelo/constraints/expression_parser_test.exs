defmodule EtheloApi.Constraints.ExpressionParserTest do
  @moduledoc """
  Validations and basic access for ExpressionParserTest
  """
  use ExUnit.Case
  alias EtheloApi.Constraints.ExpressionParser

  describe "with empty expression" do

    test "empty string" do
      result = ExpressionParser.parse("")
      assert %{error: <<error::binary>>, variables: []} = result
      assert error =~ ~r/number, method or variable/
      assert "" == result.last_parsed
      assert "" == result.parsed
    end

    test "nil" do
      result = ExpressionParser.parse(nil)
      assert %{error: <<error::binary>>, variables: []} = result
      assert error =~ ~r/number, method or variable/
      assert "" == result.last_parsed
      assert "" == result.parsed
    end

    test "only spaces" do
      result = ExpressionParser.parse(" \n")
      assert %{error: <<error::binary>>, variables: []} = result
      assert error =~ ~r/number, method or variable/
      assert "" == result.last_parsed
      assert "" == result.parsed
    end
  end

  describe "with parenthesis" do

    test "around entire expression" do
      result = ExpressionParser.parse("( 1 + 2 )")
      assert %{error: nil, variables: []} = result
      assert "( 1 + 2 )" = result.parsed
    end

    test "with new lines" do
      result = ExpressionParser.parse("\n(\n1 + 2\n)\n")
      assert %{error: nil, variables: []} = result
      assert "( 1 + 2 )" = result.parsed
    end

    test "nested" do
      result = ExpressionParser.parse("( 1 + (abc) )")
      assert %{error: nil, variables: ["abc"]} = result
      assert "( 1 + ( abc ) )" = result.parsed
    end

    test "multiple" do
      result = ExpressionParser.parse("( 1 + abc ) - 6 / (baz * boo)")
      assert %{error: nil, variables: ["abc", "baz", "boo"]} = result
      assert "( 1 + abc ) - 6 / ( baz * boo )" = result.parsed
    end

    test "bookended" do
      result = ExpressionParser.parse("boo + ( 1 + abc ) - baz")
      assert %{error: nil, variables: ["abc", "baz", "boo"]} = result
      assert "boo + ( 1 + abc ) - baz" = result.parsed
    end

    test "empty" do
      result = ExpressionParser.parse("()")
      assert %{error: <<error::binary>>, variables: []} = result
      assert error =~ ~r/brace/
      assert ")" = result.last_parsed
    end

    test "ummatched" do
      result = ExpressionParser.parse("( foo")
      assert %{error: <<error::binary>>, variables: ["foo"]} = result
      assert error =~ ~r/brace/
      assert "" = result.last_parsed
    end

  end

  describe "with method" do

    test "around entire expression" do
      result = ExpressionParser.parse("abs{ 1 + 2 }")
      assert %{error: nil, variables: [], methods: ["abs"]} = result
      assert "abs{ 1 + 2 }" = result.parsed
    end

    test "with new lines" do
      result = ExpressionParser.parse("\nabs{\n1 + 2\n}\n")
      assert %{error: nil, variables: [], methods: ["abs"]} = result
      assert "abs{ 1 + 2 }" = result.parsed
    end

    test "multiple" do
      result = ExpressionParser.parse("abs{ 1 + abc } - 6 / abs{baz * boo}")
      assert %{error: nil, variables: ["abc", "baz", "boo"], methods: ["abs"]} = result
      assert "abs{ 1 + abc } - 6 / abs{ baz * boo }" = result.parsed
    end

    test "nested" do
      result = ExpressionParser.parse("abs{baz * boo - (5 - abs{-10})}")
      assert %{error: nil, variables: ["baz", "boo"], methods: ["abs"]} = result
      assert "abs{ baz * boo - ( 5 - abs{ -10 } ) }" = result.parsed
    end

    test "bookended" do
      result = ExpressionParser.parse("boo + abs{ 1 + abc } - baz")
      assert %{error: nil, variables: ["abc", "baz", "boo"], methods: ["abs"]} = result
      assert "boo + abs{ 1 + abc } - baz" = result.parsed
    end

    test "empty" do
      result = ExpressionParser.parse("abs{}")
      assert %{error: <<error::binary>>, variables: [], methods: ["abs"]} = result
      assert error =~ ~r/method/
      assert "}" = result.last_parsed
    end

    test "ummatched" do
      result = ExpressionParser.parse("abs{ foo")
      assert %{error: <<error::binary>>, variables: ["foo"], methods: ["abs"]} = result
      assert error =~ ~r/method/
      assert "" = result.last_parsed
    end

    test "not in whitelist" do
      result = ExpressionParser.parse("round{ foo")
      assert %{error: <<error::binary>>, methods: ["round"], variables: ["foo"]} = result
      assert error =~ ~r/method/
      assert "" = result.last_parsed
    end
  end

  describe "operators" do

    test "no spaces" do
      result = ExpressionParser.parse("1+2-3*bar/foo")
      assert %{error: <<error::binary>>, variables: []} = result
      assert error =~ ~r/operator/   #"-3" is interpreted as a number
      assert "-3" = result.last_parsed
    end

    test "with spaces" do
      result = ExpressionParser.parse("1 + 2 - 3 * bar / foo")
      assert %{error: nil, variables: ["bar", "foo"]} = result
      assert "1 + 2 - 3 * bar / foo" = result.parsed
    end

    test "negatives with spaces" do
      result = ExpressionParser.parse("-1 + -2 - -3 * -4 / 5 - bar")
      assert %{error: nil, variables: ["bar"]} = result
      assert "-1 + -2 - -3 * -4 / 5 - bar" = result.parsed
    end

    test "negatives without spaces" do
      result = ExpressionParser.parse("-1+-2--3*-4/5-bar")
      assert %{error: nil, variables: ["bar"]} = result
      assert "-1 + -2 - -3 * -4 / 5 - bar" = result.parsed
    end

    test "a single negative" do
      result = ExpressionParser.parse("-21")
      assert %{error: nil, variables: []} = result
      assert "-21" = result.parsed
    end

    test "in parenthesis without operator" do
      result = ExpressionParser.parse("abc + (/)")
      assert %{error: <<error::binary>>, variables: ["abc"]} = result
      assert error =~ ~r/operator/
      assert "/" = result.last_parsed
    end

    test "unmatched" do
      result = ExpressionParser.parse("+ sixtysix")
      assert %{error: <<error::binary>>, variables: []} = result
      assert error =~ ~r/operator/
      assert "+" = result.last_parsed

      result = ExpressionParser.parse("sixtysix -")
      assert %{error: <<error::binary>>, variables: ["sixtysix"]} = result
      assert error =~ ~r/operator/
      assert "" = result.last_parsed
    end
  end

  describe "operands" do

    test "positive and negative with spaces" do
      result = ExpressionParser.parse("1 + -1 + 2.03 - -2.03")
      assert %{error: nil, variables: []} = result
      assert "1 + -1 + 2.03 - -2.03" = result.parsed
    end

    test "positive and negative without spaces" do
      result = ExpressionParser.parse("1+-1+2.03--2.03")
      assert %{error: nil, variables: []} = result
      assert "1 + -1 + 2.03 - -2.03" = result.parsed
    end

    test "variable starting with number" do
      result = ExpressionParser.parse("1a")
      assert %{error: <<error::binary>>, variables: []} = result
      assert error =~ ~r/invalid/
      assert "1a" = result.last_parsed
    end

    test "variable with decimal" do
      result = ExpressionParser.parse("bbb + b32.3")
      assert %{error: <<error::binary>>, variables: ["bbb"]} = result
      assert error =~ ~r/invalid/
      assert "b32.3" = result.last_parsed

      result = ExpressionParser.parse("foo.bar")
      assert %{error: <<error::binary>>, variables: []} = result
      assert error =~ ~r/invalid/
      assert "foo.bar" = result.last_parsed
    end

    test "variable starting with negative number" do
      result = ExpressionParser.parse("1 + -3dbs")
      assert %{error: <<error::binary>>, variables: []} = result
      assert error =~ ~r/invalid/
      assert "-3dbs" = result.last_parsed
    end

    test "valid variables with spaces" do
      result = ExpressionParser.parse("a + b1 + c_c + very_long_but_valid")
      expected = ~w(a b1 c_c very_long_but_valid)
      assert %{error: nil, variables: ^expected} = result
      assert "a + b1 + c_c + very_long_but_valid" = result.parsed
    end

    test "valid variables without spaces" do
      result = ExpressionParser.parse("a+b1-c_2/very_long_but_valid*sixtysix")
      expected = ~w(a b1 c_2 sixtysix very_long_but_valid)
      assert %{error: nil, variables: ^expected} = result
      assert "a + b1 - c_2 / very_long_but_valid * sixtysix" = result.parsed
    end

    test "alpha variables with a dash between" do
      result = ExpressionParser.parse("bu-zz")
      assert %{error: nil, variables: ["bu", "zz"]} = result
      assert "bu - zz" = result.parsed
    end

    test "variable starting with underscore" do
      result = ExpressionParser.parse("foo + far + _a + faz")
      assert %{error: <<error::binary>>, variables: ["far", "foo"]} = result
      assert error =~ ~r/invalid/
      assert "_a" = result.last_parsed
    end
  end
end
