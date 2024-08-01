defmodule EtheloApi.EngineTest do
  @moduledoc false
  use EtheloApi.DataCase
  @moduletag engine: true
  @moduletag timeout: 80_000

  alias EtheloApi.Engine

  test "engine link" do
    result = Engine.engine_task([:version, {}])
    assert {:ok, _version} = result
  end
end
