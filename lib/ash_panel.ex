defmodule AshPanel do
  @moduledoc """
  AshPanel - A flexible, composable resource management UI library for Ash Framework.

  ## Overview

  AshPanel provides automatic CRUD interfaces for Ash resources with:
  - Auto-discovery from resource definitions
  - AshComputer-powered reactive state management
  - Fully customizable components and layouts
  - Authorization-aware UI generation

  ## Quick Start

      defmodule MyAppWeb.Admin.UsersLive do
        use AshPanel.LiveView,
          resource: MyApp.Accounts.User,
          domain: MyApp.Accounts
      end

  ## Architecture

  AshPanel is built on four layers:

  1. **Introspection** - Auto-discovers resource metadata
  2. **Computation** - AshComputer-based reactive logic
  3. **Configuration** - DSL for customization
  4. **Presentation** - Pluggable UI components

  ## Customization Levels

  ### Level 1: Configuration DSL

      use AshPanel.LiveView,
        resource: User,
        domain: Accounts,
        per_page: 25

  ### Level 2: Component Swapping

      use AshPanel.LiveView,
        resource: User,
        domain: Accounts,
        components: [
          table: MyApp.Components.CustomTable
        ]

  ### Level 3: Computer Extension

      extend_computer :list_view do
        input :custom_filter do
          initial nil
        end
      end

  ### Level 4: Fully Custom

  Use just the computers and provide your own rendering.

  ## Component Behaviors

  All swappable components implement behaviors:

  - `AshPanel.Components.TableBehavior`
  - `AshPanel.Components.FilterBarBehavior`
  - `AshPanel.Components.PaginationBehavior`
  - `AshPanel.Components.FormBehavior`
  - `AshPanel.Components.DetailBehavior`

  See each behavior module for expected assigns and contracts.
  """

  @doc """
  Returns the version of AshPanel.
  """
  def version, do: Application.spec(:ash_panel, :vsn) |> to_string()
end
