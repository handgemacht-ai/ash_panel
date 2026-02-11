defmodule AshPanel.Components.FilterBarBehavior do
  @moduledoc """
  Behavior for filter bar components.

  Components implementing this behavior render filter controls
  that allow users to filter the displayed data.

  ## Expected Assigns

  - `definitions` - `list(AshPanel.Schema.FilterDefinition.t())` - Available filters
  - `values` - `map()` - Current filter values (field => value)
  - `on_change` - `String.t()` - Event to trigger when filter changes
  - `on_clear` - `String.t() | nil` - Event to trigger when clearing filters
  - `active_count` - `integer()` - Number of active filters

  ## Filter Definition Structure

  Each filter definition contains:
  - `field` - The attribute field name
  - `label` - Display label
  - `type` - `:search`, `:select`, `:number`, `:date_range`, etc.
  - `operator` - `:equals`, `:contains`, `:gte`, `:lte`, etc.
  - `options` - For select type, list of options
  - `placeholder` - Placeholder text

  ## Example Implementation

      defmodule MyApp.Components.CustomFilterBar do
        @behaviour AshPanel.Components.FilterBarBehavior
        use Phoenix.Component

        @impl true
        def render(assigns) do
          ~H\"\"\"
          <div class="filter-bar">
            <div :for={filter <- @definitions} class="filter-control">
              <%= render_filter_control(filter, @values, @on_change) %>
            </div>
            <button :if={@active_count > 0} phx-click={@on_clear}>
              Clear all ({@active_count})
            </button>
          </div>
          \"\"\"
        end
      end
  """

  @doc """
  Renders the filter bar component.

  Receives all expected assigns and returns rendered content.
  """
  @callback render(assigns :: map()) :: Phoenix.LiveView.Rendered.t()
end
