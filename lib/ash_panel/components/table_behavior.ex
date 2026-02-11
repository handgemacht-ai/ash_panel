defmodule AshPanel.Components.TableBehavior do
  @moduledoc """
  Behavior for table/list rendering components.

  Components implementing this behavior are responsible for rendering
  a list of records in whatever format they choose (table, cards, grid, etc.).

  ## Expected Assigns

  - `rows` - `list()` - The records to display
  - `columns` - `list(AshPanel.Schema.ColumnDefinition.t())` - Column definitions
  - `sortable` - `boolean() | list(atom())` - Which columns are sortable
  - `on_row_click` - `String.t() | nil` - Event to trigger on row click
  - `on_sort` - `String.t() | nil` - Event to trigger on sort change
  - `current_sort` - `{atom(), :asc | :desc} | nil` - Current sort state
  - `selectable` - `boolean()` - Whether rows can be selected
  - `selected_ids` - `list()` - Currently selected row IDs
  - `on_select` - `String.t() | nil` - Event to trigger on selection change

  ## Example Implementation

      defmodule MyApp.Components.CustomTable do
        @behaviour AshPanel.Components.TableBehavior
        use Phoenix.Component

        @impl true
        def render(assigns) do
          ~H\"\"\"
          <table class="custom-table">
            <thead>
              <tr>
                <th :for={col <- @columns}>
                  {col.label}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr :for={row <- @rows}>
                <td :for={col <- @columns}>
                  {render_cell(row, col)}
                </td>
              </tr>
            </tbody>
          </table>
          \"\"\"
        end

        defp render_cell(row, column) do
          Map.get(row, column.field)
        end
      end

  ## Using a Custom Table

      use AshPanel.LiveView,
        resource: User,
        domain: Accounts,
        components: [
          table: MyApp.Components.CustomTable
        ]
  """

  @doc """
  Renders the table component.

  Receives all expected assigns and returns rendered content.
  """
  @callback render(assigns :: map()) :: Phoenix.LiveView.Rendered.t()
end
