defmodule Engine.Driver.Messenger do
  use GenServer
  require Timex
  require Logger

  def start_link(config \\ [], options \\ []) do
    GenServer.start_link(__MODULE__, config, options)
  end

  def init(config) do
    key = Keyword.get(config, :preemption_key)
    topic = "engine_task:#{key}"
    caller = Keyword.get(config, :caller)
    task_pid = Keyword.get(config, :task_pid)
    Phoenix.PubSub.broadcast(:engine_driver_internal, "engine_task:#{key}", {:started, task_pid, Timex.now})
    Phoenix.PubSub.subscribe(:engine_driver_internal, "engine_task:#{key}")
    {:ok, %{topic: topic, caller: caller, task_pid: task_pid}}
  end

  def handle_info({:started, task_pid, start_time}, state) do
    if task_pid != state.task_pid do
      Logger.debug("#{inspect state.task_pid} pre-empted by #{inspect task_pid}")
      GenServer.reply(state.caller, {:error, {:error, "pre_empted" }}) 
      Process.exit(self(), :preempted)
    end
    {:noreply, state}
  end
end
