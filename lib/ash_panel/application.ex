defmodule AshPanel.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # No persistent processes needed for now
      # Future: Could add a cache for introspection results
    ]

    opts = [strategy: :one_for_one, name: AshPanel.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
