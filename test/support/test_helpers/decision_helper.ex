defmodule EtheloApi.Structure.TestHelper.DecisionHelper do
  @moduledoc false

  import EtheloApi.Structure.TestHelper.GenericHelper
  import ExUnit.Assertions

  def empty_attrs() do
    %{
      info: nil, slug: nil, title: nil, keywords: [],
      published_decision_hash: nil, preview_decision_hash: nil,
      influent_hash: nil,  weighting_hash: nil,
    }
  end

  def invalid_attrs(deps \\ %{}) do
    %{
      slug: "  ", title: "@@@", public: 3, keywords: 6, copyable: "3",
      max_users: "fourty seven", language: "klingon"
    }

  end

  def valid_attrs() do
    %{
      title: "Title", slug: "slug", keywords: ["test", "foo", "bar"],
      info: "info", copyable: true, max_users: 19, language: "en",
      published_decision_hash: "A",  preview_decision_hash: "B",
      influent_hash: "C",  weighting_hash: "D",
    }
  end

  def assert_equivalent(expected, result) do
    assert expected.title == result.title
    assert_equivalent_slug(expected.slug, result.slug)
    assert expected.info == result.info
    assert expected.copyable == result.copyable
    assert expected.max_users == result.max_users
    assert expected.language == result.language
    assert expected.keywords == result.keywords
  end

  def to_graphql_attrs(attrs) do
    attrs
  end
end
