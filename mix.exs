defmodule AshPanel.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/handgemacht-ai/ash_panel"

  def project do
    [
      app: :ash_panel,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {AshPanel.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Ash Framework
      {:ash, "~> 3.0"},
      {:spark, "~> 2.0"},

      # Phoenix & LiveView
      {:phoenix_live_view, "~> 1.0"},

      # AshComputer for reactive state
      {:ash_computer, "~> 0.2.0"},

      # Utilities
      {:inflex, "~> 2.0"},

      # Development & Testing
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ash_scenario, "~> 0.6", only: :test}
    ]
  end

  defp description do
    """
    A flexible, composable resource management UI library for Ash Framework applications.
    Features automatic resource introspection, AshComputer-powered reactive state,
    and fully customizable components and layouts.
    """
  end

  defp package do
    [
      name: "ash_panel",
      licenses: ["MIT"],
      maintainers: ["Marco Taubmann"],
      files: ~w(
        lib
        .formatter.exs
        mix.exs
        README.md
        LICENSE
        CHANGELOG.md
        USAGE_EXAMPLE.md
        ROUTER_EXAMPLE.md
        ZERO_CONFIG_EXAMPLE.md
      ),
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      name: "AshPanel",
      source_url: @source_url,
      source_ref: "v#{@version}",
      homepage_url: @source_url,
      extras: [
        "README.md",
        "CHANGELOG.md",
        "USAGE_EXAMPLE.md",
        "ROUTER_EXAMPLE.md",
        "ZERO_CONFIG_EXAMPLE.md"
      ],
      groups_for_extras: [
        Guides: [
          "USAGE_EXAMPLE.md",
          "ROUTER_EXAMPLE.md",
          "ZERO_CONFIG_EXAMPLE.md"
        ]
      ],
      groups_for_modules: [
        Core: [
          AshPanel,
          AshPanel.Application
        ],
        Components: [
          AshPanel.Components.TableBehavior,
          AshPanel.Components.FilterBarBehavior,
          AshPanel.Components.PaginationBehavior,
          AshPanel.Components.DefaultTable,
          AshPanel.Components.DefaultFilterBar,
          AshPanel.Components.DefaultPagination
        ],
        Computers: [
          AshPanel.Computers.Filters,
          AshPanel.Computers.Pagination
        ],
        Views: [
          AshPanel.Views.ListView
        ],
        Schema: [
          AshPanel.Schema.ResourceSchema,
          AshPanel.Schema.AttributeSchema,
          AshPanel.Schema.FilterDefinition
        ],
        Introspection: [
          AshPanel.Introspection
        ]
      ]
    ]
  end
end
