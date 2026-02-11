defmodule AshPanel.Components.PaginationBehavior do
  @moduledoc """
  Behavior for pagination components.

  Components implementing this behavior render pagination controls
  that allow users to navigate through pages of data.

  ## Expected Assigns

  - `current_page` - `integer()` - Current page number (1-indexed)
  - `total_pages` - `integer()` - Total number of pages
  - `total_count` - `integer()` - Total number of items across all pages
  - `page_size` - `integer()` - Number of items per page
  - `has_prev` - `boolean()` - Whether there is a previous page
  - `has_next` - `boolean()` - Whether there is a next page
  - `prev_event` - `String.t()` - Event to trigger for previous page
  - `next_event` - `String.t()` - Event to trigger for next page
  - `goto_event` - `String.t() | nil` - Event to trigger for specific page
  - `item_name` - `String.t()` - Name of items (e.g., "users", "posts")

  ## Example Implementation

      defmodule MyApp.Components.CustomPagination do
        @behaviour AshPanel.Components.PaginationBehavior
        use Phoenix.Component

        @impl true
        def render(assigns) do
          ~H\"\"\"
          <div class="pagination">
            <button
              phx-click={@prev_event}
              disabled={!@has_prev}
            >
              Previous
            </button>

            <span>
              Page {@current_page} of {@total_pages}
              ({@total_count} {@item_name} total)
            </span>

            <button
              phx-click={@next_event}
              disabled={!@has_next}
            >
              Next
            </button>
          </div>
          \"\"\"
        end
      end
  """

  @doc """
  Renders the pagination component.

  Receives all expected assigns and returns rendered content.
  """
  @callback render(assigns :: map()) :: Phoenix.LiveView.Rendered.t()
end
