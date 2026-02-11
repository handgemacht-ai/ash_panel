defmodule AshPanel.Components.DefaultTable do
  @moduledoc """
  Default table component implementation.

  Implements `AshPanel.Components.TableBehavior` with Tailwind CSS styling.
  Renders a responsive table with sortable columns and clickable rows.
  """

  @behaviour AshPanel.Components.TableBehavior

  use Phoenix.Component

  @impl true
  def render(assigns) do
    # Add default values for optional assigns
    assigns =
      assigns
      |> Map.put_new(:on_row_click, nil)
      |> Map.put_new(:on_sort, nil)
      |> Map.put_new(:current_sort, nil)
      |> Map.put_new(:selectable, false)
      |> Map.put_new(:selected_ids, [])
      |> Map.put_new(:on_select, nil)
      |> Map.put_new(:empty_message, "No records found")
      |> Map.put_new(:empty_description, "No records match the current criteria.")

    ~H"""
    <div class="mt-8 flow-root">
      <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
        <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
          <table class="min-w-full divide-y divide-gray-300">
            <thead>
              <tr>
                <th
                  :if={@selectable}
                  scope="col"
                  class="relative px-6 sm:w-12 sm:px-6"
                >
                  <input
                    type="checkbox"
                    class="absolute left-4 top-1/2 -mt-2 h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-600"
                    phx-click={@on_select}
                    phx-value-action="toggle-all"
                  />
                </th>
                <th
                  :for={column <- @columns}
                  scope="col"
                  class={[
                    "py-3.5 text-sm font-semibold text-gray-900",
                    column_padding_class(column),
                    column_align_class(column)
                  ]}
                >
                  <%= if column.sortable && @on_sort do %>
                    <button
                      phx-click={@on_sort}
                      phx-value-field={column.field}
                      class="group inline-flex hover:text-indigo-600"
                    >
                      {column.label}
                      <%= if @current_sort && elem(@current_sort, 0) == column.field do %>
                        <span class="ml-2 flex-none rounded text-gray-400">
                          <%= if elem(@current_sort, 1) == :asc do %>
                            ↑
                          <% else %>
                            ↓
                          <% end %>
                        </span>
                      <% end %>
                    </button>
                  <% else %>
                    {column.label}
                  <% end %>
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
              <tr
                :for={row <- @rows}
                class={[
                  "hover:bg-gray-50",
                  @on_row_click && "cursor-pointer"
                ]}
                phx-click={@on_row_click}
                phx-value-id={@on_row_click && get_row_id(row)}
              >
                <td :if={@selectable} class="relative px-6 sm:w-12 sm:px-6">
                  <input
                    type="checkbox"
                    class="absolute left-4 top-1/2 -mt-2 h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-600"
                    checked={get_row_id(row) in @selected_ids}
                    phx-click={@on_select}
                    phx-value-id={get_row_id(row)}
                  />
                </td>
                <td
                  :for={column <- @columns}
                  class={[
                    "whitespace-nowrap py-4 text-sm",
                    column_padding_class(column),
                    column_align_class(column),
                    column_color_class(column)
                  ]}
                >
                  <%= render_cell_value(row, column) %>
                </td>
              </tr>
            </tbody>
          </table>

          <!-- Empty state -->
          <div :if={@rows == []} class="text-center py-12">
            <svg
              class="mx-auto h-12 w-12 text-gray-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              aria-hidden="true"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
              />
            </svg>
            <h3 class="mt-2 text-sm font-semibold text-gray-900">{@empty_message}</h3>
            <p class="mt-1 text-sm text-gray-500">{@empty_description}</p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Private helpers

  defp get_row_id(row) when is_map(row) do
    Map.get(row, :id) || Map.get(row, "id")
  end

  defp get_row_id(_row), do: nil

  defp render_cell_value(row, column) do
    value = Map.get(row, column.field)

    cond do
      column.formatter -> column.formatter.(value)
      column.component -> column.component.(%{value: value, row: row})
      is_boolean(value) -> if value, do: "Yes", else: "No"
      is_nil(value) -> "-"
      true -> to_string(value)
    end
  end

  defp column_padding_class(column) do
    # Check if this is a primary/id field to apply special padding
    if column.field in [:id, :email, :name, :title] do
      "pl-4 pr-3 sm:pl-0"
    else
      "px-3"
    end
  end

  defp column_align_class(column) do
    case Map.get(column, :align, :left) do
      :left -> "text-left"
      :center -> "text-center"
      :right -> "text-right"
    end
  end

  defp column_color_class(column) do
    # Check if this is a primary/id field to apply emphasized styling
    if column.field in [:id, :email, :name, :title] do
      "text-gray-900 font-medium"
    else
      "text-gray-500"
    end
  end
end
