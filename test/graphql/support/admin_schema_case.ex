defmodule GraphQL.EtheloApi.AdminSchemaCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer, plus some additional graphql helpers.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate
  require Logger

  using do
    quote do
      use EtheloApi.DataCase

      import Kronky.TestHelper
      alias Kronky.ValidationMessage

      def evaluate_graphql(query, options \\ []) do
        Absinthe.run(query, EtheloApi.GraphQL.AdminSchema, options)
      end
    end
  end

end
