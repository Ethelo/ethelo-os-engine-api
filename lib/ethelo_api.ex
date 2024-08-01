defmodule EtheloApi.Application do
  @moduledoc """
  The Ethelo Application Service.

  The ethelo system business domain lives in this application.

  Exposes API to clients such as the `EtheloApi.Web` application
  for use in channels, controllers, and elsewhere.
  """
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    Supervisor.start_link([
      supervisor(EtheloApi.Repo, []),
    ], strategy: :one_for_one, name: EtheloApi.Supervisor)
  end
end
