defmodule EtheloApi.Engine do
  @moduledoc """
  Connects to the C++ engine to run solves
  """

  use Task

  require Logger

  def engine_task(args) do
    task =
      Task.Supervisor.async_nolink(
        {:via, PartitionSupervisor, {EtheloApi.EngineTaskSupervisors, self()}},
        EtheloApi.Engine,
        :call_engine,
        args
      )

    Task.await(task)
  end

  def start_link(args) do
    Task.start_link(__MODULE__, :call_engine, [args])
  end

  def call_engine(function, args) do
    driver = Application.get_env(:ethelo_api, :engine_driver),

    path = Path.join([List.to_string(:code.priv_dir(:ethelo_api)), driver])

    if File.exists?(path) do
      port = Port.open({:spawn, path}, [{:packet, 4}, :binary, :nouse_stdio])
      send(port, {self(), {:command, :erlang.term_to_binary({function, args})}})
      |> recieve_engine()
    else
      {:error, "Engine Driver not Found at #{path}"}
    end
  end

  def recieve_engine(_, timeout \\ 50000) do
    receive do
       {port, {:data, data}} ->
         IO.inspect(data, printable_limit: :infinity, limit: :infinity, label: "data")

        :erlang.binary_to_term(data)
    after
      timeout -> {:error, "no result"}
    end
  end

end
