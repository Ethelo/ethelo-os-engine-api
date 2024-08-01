defmodule EtheloApi.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use EtheloApi.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias EtheloApi.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import EtheloApi.DataCase
      import EtheloApi.TestHelper.GenericHelper
      alias Ecto.Changeset
      alias AbsintheErrorPayload.ValidationMessage
    end
  end

  setup tags do
    EtheloApi.DataCase.setup_sandbox(tags)
    :ok
  end

  @doc """
  Sets up the sandbox based on the test tags.
  """
  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(EtheloApi.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in error_map(changeset).password
      assert %{password: ["password is too short"]} = error_map(changeset)
  """
  def error_map(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        atom_key = String.to_existing_atom(key)
        opts |> Keyword.get(atom_key, key) |> to_string()
      end)
    end)
  end

  @spec load_support_file(binary) :: binary
  def load_support_file(filename) do
    File.read!(Path.join("test/support/json", filename))
  end

  @spec load_priv_file(binary) :: binary
  def load_priv_file(filename) do
    File.read!(Path.join(:code.priv_dir(:ethelo_api), filename))
  end

  @spec write_file(binary, binary) :: :ok | {:error, atom}
  def write_file(filename, content) when is_binary(content) do
    # credo:disable-for-next-line Credo.Check.Warning.IoInspect
    path = Path.join([Application.app_dir(:ethelo_api), filename]) |> IO.inspect()
    File.write(path, content)
  end
end
