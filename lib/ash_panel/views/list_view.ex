defmodule AshPanel.Views.ListView do
  @moduledoc """
  Complete list view that orchestrates filters, table, and pagination.

  This is a container component that brings together all the pieces needed
  for a list view: filter bar, table, and pagination controls.

  ## Usage

      <AshPanel.Views.ListView.render
        filter_definitions={@filter_definitions}
        filter_values={@filters_values}
        filter_count={@filters_filter_count}
        on_filter_change={event(:filters, :set_filter)}
        on_filter_clear={event(:filters, :clear_all)}

        rows={@list_view_query_result}
        columns={@list_view_columns}
        on_row_click={event(:detail_view, :select_record)}
        on_sort={event(:list_view, :set_sort)}
        current_sort={{@list_view_sort_field, @list_view_sort_order}}

        current_page={@list_view_page}
        total_pages={@list_view_total_pages}
        total_count={@list_view_total_count}
        has_prev={@list_view_has_prev_page}
        has_next={@list_view_has_next_page}
        on_prev_page={event(:list_view, :prev_page)}
        on_next_page={event(:list_view, :next_page)}

        page_size={@list_view_page_size}
        page_size_options={[10, 25, 50, 100]}
        on_page_size_change={event(:list_view, :set_page_size)}

        item_name="users"
      />

  ## Custom Components

  You can override individual components:

      <AshPanel.Views.ListView.render
        ...
        table_component={MyApp.CustomTable}
        filter_bar_component={MyApp.CustomFilterBar}
        pagination_component={MyApp.CustomPagination}
      />
  """

  use Phoenix.Component

  alias AshPanel.Components.{
    DefaultTable,
    DefaultFilterBar,
    DefaultPagination,
    DefaultPageSizeSelector
  }

  @doc """
  Renders a complete list view with filters, table, and pagination.
  """
  def render(assigns) do
    # Set default components
    assigns =
      assigns
      |> Map.put_new(:table_component, DefaultTable)
      |> Map.put_new(:filter_bar_component, DefaultFilterBar)
      |> Map.put_new(:pagination_component, DefaultPagination)
      |> Map.put_new(:page_size_selector_component, DefaultPageSizeSelector)
      |> Map.put_new(:show_filters?, true)
      |> Map.put_new(:show_page_size?, true)
      |> Map.put_new(:empty_message, "No records found")
      |> Map.put_new(:empty_description, "No records match the current criteria.")

    ~H"""
    <div class="ash-panel-list-view">
      <!-- Header with optional page size selector -->
      <div :if={@show_page_size?} class="flex justify-end mb-4">
        <%= @page_size_selector_component.render(%{
          current_size: @page_size,
          on_change: @on_page_size_change,
          options: Map.get(assigns, :page_size_options, [10, 25, 50])
        }) %>
      </div>

      <!-- Filter bar -->
      <%= if @show_filters? && Map.get(assigns, :filter_definitions) do %>
        <%= @filter_bar_component.render(%{
          definitions: @filter_definitions,
          values: @filter_values,
          on_change: @on_filter_change,
          on_clear: Map.get(assigns, :on_filter_clear),
          active_count: Map.get(assigns, :filter_count, 0)
        }) %>
      <% end %>

      <!-- Table -->
      <%= @table_component.render(%{
        rows: @rows,
        columns: @columns,
        on_row_click: Map.get(assigns, :on_row_click),
        on_sort: Map.get(assigns, :on_sort),
        current_sort: Map.get(assigns, :current_sort),
        selectable: Map.get(assigns, :selectable, false),
        selected_ids: Map.get(assigns, :selected_ids, []),
        on_select: Map.get(assigns, :on_select),
        empty_message: @empty_message,
        empty_description: @empty_description
      }) %>

      <!-- Pagination -->
      <%= @pagination_component.render(%{
        current_page: @current_page,
        total_pages: @total_pages,
        total_count: @total_count,
        has_prev: @has_prev,
        has_next: @has_next,
        prev_event: @on_prev_page,
        next_event: @on_next_page,
        item_name: Map.get(assigns, :item_name, "items")
      }) %>
    </div>
    """
  end
end
