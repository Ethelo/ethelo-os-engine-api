defmodule EtheloApi.MixProject do
  use Mix.Project

  def project do
    [
      app: :ethelo_api,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env),
     start_permanent: Mix.env == :prod,
      deps: deps()
      aliases: aliases(),
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {EtheloApi.Application, []},
      extra_applications: [:logger, :runtime_tools, :crypto, :runtime_tools, :inets, :distillery, :poolboy],
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

 # Dependencies can be Hex packages:
 #
 #   {:my_dep, "~> 0.3.0"}
 #
 # Or git/path repositories:
 #
 #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
 #
 #
  defp deps do
    [
      {:auto_linker, "~> 1.0"},
      {:decimal, "~> 1.0"},
      {:distillery, "~> 1.0"},
      {:ecto, "~> 2.1"},
      {:ecto_enum, "~> 1.0"},
      {:exprof, "~> 0.2.0"},
      {:faker, "~> 0.8"},
      {:inflex, "~> 1.10.0"},
      {:ok, "~> 2.0.0"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_pubsub_redis, "~> 2.1"},
      {:poison, "~> 3.0"},
      {:poison, "~> 3.0"},
      {:poolboy, "~> 1.5.1"},
      {:postgrex, ">= 0.0.0"},
      {:timex, "~> 3.0"},
      {:timex_ecto, "~> 3.0"},
      {:credo, "~> 0.8.4", only: [:dev, :test]},
      {:earmark, "~> 1.2.2", only: [:dev, :test]},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false},
    ]
end
  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
    "ecto.reset": ["ecto.drop", "ecto.setup"],
    "ecto.setup": ["ecto.create", "ecto.migrate", "ecto.seed"],
   ]
   "ecto.setup": [
        "ecto.create",
        "ecto.load --skip-if-loaded",
        "ecto.migrate",
        "ecto.seed"
      ],
   test: [
        "ecto.drop --quiet",
        "ecto.create --quiet",
        "ecto.load --skip-if-loaded",
        "ecto.migrate --quiet",
        "test"
      ]
  end
end
