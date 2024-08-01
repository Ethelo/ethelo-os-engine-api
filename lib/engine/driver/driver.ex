defmodule Engine.Driver do
    use Application

    def start(_type, _args) do
        import Supervisor.Spec

        # Fetch parameters
        params_node = Application.get_env(:engine_driver, :node, [])
        params_pools = Enum.into(Application.get_env(:engine_driver, :pools, []), %{default: []})

        # Process pool parameters
        params_pools = Enum.reduce(params_pools, %{}, fn({key, params}, acc) ->
            Map.put(acc, key, [
                name: {:local, String.to_atom("Engine.Driver_node_pool_" <> Atom.to_string(key))},
                worker_module: Engine.Driver.Engine,
                size: Keyword.get(params, :size, 10),
                max_overflow: Keyword.get(params, :max_overflow, 10)
            ])
        end)

        # Setup pool specifications
        pool_specs = Enum.map(params_pools, fn({_key, params}) ->
            {:local, name} = Keyword.fetch!(params, :name)
            :poolboy.child_spec(name, params, [])
        end)

        # Process node parameters
        params_node = Keyword.put(params_node, :dispatcher, Engine.Driver.Node.Dispatcher)
                   |> Keyword.put(:pools, Enum.reduce(params_pools, %{}, fn({key, params}, acc) ->
                        {:local, name} = Keyword.fetch!(params, :name)
                        Map.put(acc, key, name)
                    end))

        children = [
            worker(Engine.Driver.Node, [params_node, [name: Engine.Driver.Node]]),
            supervisor(Task.Supervisor, [[name: Engine.Driver.Node.Dispatcher]]),
            #TODO: setup K8 with Distributed Elixir (PG2) and get rid of redis
            supervisor(Phoenix.PubSub.Redis,
            [:engine_driver_internal, [
               host: Application.get_env(:engine_driver, :redis_host),
              pool_size: 3,
              node_name: Ecto.UUID.generate()
              ]]),
        ] ++ pool_specs

        Supervisor.start_link(children,
            [strategy: :one_for_one, name: Engine.Driver.Supervisor])
    end

    def call(function, arguments \\ {}, options \\ []) do
        Engine.Driver.Node.call(Engine.Driver.Node, function, arguments, options)
    end
end
