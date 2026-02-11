defmodule AshPanel.Views.DetailView do
  @moduledoc """
  Complete detail view that displays a single record with its attributes and relationships.

  This is a container component that renders a record's details in a structured layout,
  typically used in a modal or dedicated page.

  ## Usage

      <AshPanel.Views.DetailView.render
        record={@detail_view_record}
        attributes={@detail_view_attributes}
        relationships={@detail_view_relationships}
        actions={@detail_view_actions}
        loading?={@detail_view_loading?}
        not_found?={@detail_view_not_found?}
        error?={@detail_view_error?}
        on_close={event(:detail_view, :close)}
        on_action={&handle_action/1}
      />

  ## As a Modal

      <.detail_modal :if={@detail_view_show_modal}>
        <AshPanel.Views.DetailView.render ... />
      </.detail_modal>

  ## Custom Layout

  You can provide a custom layout for attributes:

      <AshPanel.Views.DetailView.render
        ...
        layout={:two_column}  # :single_column | :two_column | :grid
      />
  """

  use Phoenix.Component

  @doc """
  Renders a detail view for a single record.
  """
  def render(assigns) do
    assigns =
      assigns
      |> Map.put_new(:layout, :single_column)
      |> Map.put_new(:show_actions?, true)
      |> Map.put_new(:show_relationships?, true)
      |> Map.put_new(:on_action, nil)

    ~H"""
    <div class="ash-panel-detail-view">
      <%= cond do %>
        <% @loading? -> %>
          <div class="flex items-center justify-center py-12">
            <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
          </div>

        <% @not_found? -> %>
          <div class="text-center py-12">
            <svg
              class="mx-auto h-12 w-12 text-gray-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M12 12h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
            <h3 class="mt-2 text-sm font-semibold text-gray-900">Record not found</h3>
            <p class="mt-1 text-sm text-gray-500">The requested record could not be found.</p>
          </div>

        <% @error? -> %>
          <div class="text-center py-12">
            <svg
              class="mx-auto h-12 w-12 text-red-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
            <h3 class="mt-2 text-sm font-semibold text-gray-900">Error loading record</h3>
            <p class="mt-1 text-sm text-gray-500">There was an error loading this record.</p>
          </div>

        <% @record -> %>
          <div class="space-y-6">
            <!-- Attributes Section -->
            <div>
              <h3 class="text-lg font-medium leading-6 text-gray-900 mb-4">Details</h3>
              <.attribute_grid attributes={@attributes} record={@record} layout={@layout} />
            </div>

            <!-- Relationships Section -->
            <%= if @show_relationships? && length(@relationships) > 0 do %>
              <div>
                <h3 class="text-lg font-medium leading-6 text-gray-900 mb-4">Relationships</h3>
                <.relationship_list relationships={@relationships} record={@record} />
              </div>
            <% end %>

            <!-- Actions Section -->
            <%= if @show_actions? && length(@actions) > 0 do %>
              <div class="flex gap-2 pt-4 border-t">
                <%= for action <- @actions do %>
                  <button
                    :if={@on_action}
                    phx-click={@on_action}
                    phx-value-action={action.name}
                    class={action_button_class(action)}
                  >
                    {action.button_text || action.label}
                  </button>
                <% end %>
              </div>
            <% end %>
          </div>

        <% true -> %>
          <div class="text-center py-12">
            <p class="text-sm text-gray-500">No record selected</p>
          </div>
      <% end %>
    </div>
    """
  end

  defp attribute_grid(assigns) do
    ~H"""
    <dl class={grid_class(@layout)}>
      <%= for attr <- @attributes do %>
        <div class="border-t border-gray-100 px-4 py-4 sm:col-span-1 sm:px-0">
          <dt class="text-sm font-medium leading-6 text-gray-900">
            {attr.label}
          </dt>
          <dd class="mt-1 text-sm leading-6 text-gray-700">
            <%= display_attribute_value(@record, attr) %>
          </dd>
        </div>
      <% end %>
    </dl>
    """
  end

  defp relationship_list(assigns) do
    ~H"""
    <div class="space-y-3">
      <%= for rel <- @relationships do %>
        <div class="border rounded-lg p-4">
          <h4 class="text-sm font-medium text-gray-900 mb-2">
            {rel.label}
            <span class="text-xs text-gray-500 ml-2">
              ({if rel.cardinality == :one, do: "one", else: "many"})
            </span>
          </h4>
          <div class="text-sm text-gray-600">
            <%= display_relationship_value(@record, rel) %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp grid_class(:single_column), do: "divide-y divide-gray-100"

  defp grid_class(:two_column),
    do: "grid grid-cols-1 sm:grid-cols-2 gap-x-4 divide-y divide-gray-100"

  defp grid_class(:grid), do: "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4"

  defp display_attribute_value(record, attr) do
    value = Map.get(record, attr.name)

    cond do
      attr.formatter -> attr.formatter.(value)
      is_nil(value) -> "-"
      true -> to_string(value)
    end
  end

  defp display_relationship_value(record, rel) do
    value = Map.get(record, rel.name)

    cond do
      is_nil(value) -> "-"
      rel.cardinality == :one -> display_single_relation(value, rel.display_field)
      rel.cardinality == :many -> display_many_relations(value, rel.display_field)
      true -> "-"
    end
  end

  defp display_single_relation(record, display_field) when is_map(record) do
    Map.get(record, display_field) || Map.get(record, :id) || "Related record"
  end

  defp display_single_relation(_, _), do: "-"

  defp display_many_relations(records, _display_field) when is_list(records) do
    count = length(records)

    if count > 0 do
      "#{count} related #{if count == 1, do: "record", else: "records"}"
    else
      "No related records"
    end
  end

  defp display_many_relations(_, _), do: "-"

  defp action_button_class(action) do
    base =
      "inline-flex items-center px-4 py-2 border text-sm font-medium rounded-md focus:outline-none focus:ring-2 focus:ring-offset-2"

    if action.destructive? do
      "#{base} border-red-300 text-red-700 bg-white hover:bg-red-50 focus:ring-red-500"
    else
      "#{base} border-indigo-600 text-white bg-indigo-600 hover:bg-indigo-700 focus:ring-indigo-500"
    end
  end
end
