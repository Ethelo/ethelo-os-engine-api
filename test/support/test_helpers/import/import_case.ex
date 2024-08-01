defmodule EtheloApi.ImportCase do
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

      import ExUnit.Assertions
      import EtheloApi.TestHelper.ImportHelper

      alias EtheloApi.TestHelper.ImportFactory
      alias EtheloApi.Import.ImportSegment
      alias EtheloApi.Import.ImportProcess
      alias EtheloApi.Import.ImportError

      setup_all do
        input = ImportFactory.get_input()
        process = %ImportProcess{valid?: true, complete?: false, input: input}
        %{input: input, process: process}
      end

      setup context do
        ImportFactory.setup_decision(context)
      end
    end
  end
end
