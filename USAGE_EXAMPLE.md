# AshPanel Usage Examples

This guide shows how to use AshPanel's auto-generated computers to build complete admin interfaces.

## Quick Start: Zero-Config Admin

The simplest way to create a full CRUD interface:

```elixir
defmodule MyAppWeb.Admin.UsersLive do
  use MyAppWeb, :live_view
  use AshComputer.LiveView

  # This generates all three computers (list, detail, form)
  use AshPanel.ComputerGenerator,
    resource: MyApp.Accounts.User,
    domain: MyApp.Accounts,
    views: [:list, :detail, :form]

  # Also generate filters computer
  use AshPanel.Computers.Filters,
    resource: MyApp.Accounts.User,
    fields: [:email, :role, :display_name]

  @impl true
  def mount(_params, _session, socket) do
    executor =
      AshComputer.Executor.new()
      |> AshComputer.Executor.add_computer(__MODULE__, :filters)
      |> AshComputer.Executor.add_computer(__MODULE__, :list_view)
      |> AshComputer.Executor.add_computer(__MODULE__, :detail_view)
      |> AshComputer.Executor.add_computer(__MODULE__, :form_view)
      # Connect filters to list view
      |> AshComputer.Executor.connect(
        from: {:filters, :active_filters},
        to: {:list_view, :filters}
      )
      |> AshComputer.Executor.initialize()
      |> then(fn exec ->
        exec
        |> AshComputer.Executor.start_frame()
        |> AshComputer.Executor.set_input(:list_view, :actor, socket.assigns.current_user)
        |> AshComputer.Executor.set_input(:detail_view, :actor, socket.assigns.current_user)
        |> AshComputer.Executor.set_input(:form_view, :actor, socket.assigns.current_user)
        |> AshComputer.Executor.commit_frame()
      end)

    socket =
      socket
      |> assign(:__executor__, executor)
      |> assign(:filter_definitions, filter_definitions())
      |> AshComputer.LiveView.Helpers.sync_executor_to_assigns()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <!-- Header -->
      <div class="flex justify-between items-center mb-8">
        <h1 class="text-3xl font-bold">Users</h1>
        <button
          phx-click={event(:form_view, :open_create)}
          class="bg-indigo-600 text-white px-4 py-2 rounded-md"
        >
          Create User
        </button>
      </div>

      <!-- Filters -->
      <AshPanel.Components.DefaultFilterBar.render
        definitions={@filter_definitions}
        values={@filters_values}
        on_change={event(:filters, :set_filter)}
        on_clear={event(:filters, :clear_all)}
        active_count={@filters_filter_count}
      />

      <!-- Table -->
      <AshPanel.Components.DefaultTable.render
        rows={@list_view_query_result}
        columns={@list_view_columns}
        on_row_click={event(:detail_view, :select_record)}
        on_sort={event(:list_view, :set_sort)}
        current_sort={{@list_view_sort_field, @list_view_sort_order}}
      />

      <!-- Pagination -->
      <AshPanel.Components.DefaultPagination.render
        current_page={@list_view_page}
        total_pages={@list_view_total_pages}
        total_count={@list_view_total_count}
        has_prev={@list_view_has_prev_page}
        has_next={@list_view_has_next_page}
        prev_event={event(:list_view, :prev_page)}
        next_event={event(:list_view, :next_page)}
        item_name="users"
      />

      <!-- Detail Modal -->
      <.detail_modal :if={@detail_view_show_modal} />

      <!-- Form Modal -->
      <.form_modal :if={@form_view_show_form} />
    </div>
    """
  end

  defp detail_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center">
      <div class="bg-white rounded-lg p-6 max-w-2xl w-full">
        <div class="flex justify-between items-center mb-4">
          <h2 class="text-2xl font-bold">User Details</h2>
          <button phx-click={event(:detail_view, :close)} class="text-gray-500">
            ✕
          </button>
        </div>

        <%= if @detail_view_record do %>
          <div class="space-y-4">
            <%= for attr <- @detail_view_attributes do %>
              <div>
                <label class="font-medium text-gray-700">{attr.label}</label>
                <div class="text-gray-900">
                  {display_attribute(@detail_view_record, attr)}
                </div>
              </div>
            <% end %>

            <!-- Actions -->
            <div class="flex gap-2 mt-6">
              <button
                phx-click={event(:form_view, :open_edit)}
                phx-value-id={@detail_view_record.id}
                class="bg-indigo-600 text-white px-4 py-2 rounded-md"
              >
                Edit
              </button>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp form_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center">
      <div class="bg-white rounded-lg p-6 max-w-2xl w-full">
        <div class="flex justify-between items-center mb-4">
          <h2 class="text-2xl font-bold">
            {if @form_view_mode == :create, do: "Create User", else: "Edit User"}
          </h2>
          <button phx-click={event(:form_view, :close)} class="text-gray-500">
            ✕
          </button>
        </div>

        <form phx-submit={event(:form_view, :submit)}>
          <div class="space-y-4">
            <%= for field <- @form_view_fields do %>
              <div>
                <label class="block font-medium text-gray-700">{field.label}</label>
                <%= render_form_field(field, event(:form_view, :set_field)) %>
              </div>
            <% end %>
          </div>

          <div class="flex gap-2 mt-6">
            <button
              type="submit"
              class="bg-indigo-600 text-white px-4 py-2 rounded-md"
              disabled={@form_view_submitting?}
            >
              {if @form_view_mode == :create, do: "Create", else: "Update"}
            </button>
            <button
              type="button"
              phx-click={event(:form_view, :reset)}
              class="bg-gray-300 text-gray-700 px-4 py-2 rounded-md"
            >
              Reset
            </button>
          </div>
        </form>
      </div>
    </div>
    """
  end

  defp display_attribute(record, attr) do
    value = Map.get(record, attr.name)

    if attr.formatter do
      attr.formatter.(value)
    else
      to_string(value || "-")
    end
  end

  defp render_form_field(field, on_change) do
    # Render appropriate input based on field_type
    # This would be more sophisticated in real implementation
    assigns = %{field: field, on_change: on_change}

    ~H"""
    <input
      type="text"
      name="value"
      value={@field.current_value || ""}
      phx-change={@on_change}
      phx-value-field={@field.name}
      class="mt-1 block w-full rounded-md border-gray-300"
    />
    """
  end
end
```

## Customization Examples

### 1. List View Only

```elixir
defmodule MyAppWeb.Admin.ReportsLive do
  use MyAppWeb, :live_view
  use AshComputer.LiveView

  # Just the list view, no detail or form
  use AshPanel.ComputerGenerator,
    resource: MyApp.Reports.Report,
    domain: MyApp.Reports,
    views: [:list]

  # Rest of implementation...
end
```

### 2. With Overrides

```elixir
defmodule MyAppWeb.Admin.ProductsLive do
  use MyAppWeb, :live_view
  use AshComputer.LiveView

  use AshPanel.ComputerGenerator,
    resource: MyApp.Catalog.Product,
    domain: MyApp.Catalog,
    views: [:list, :detail, :form],
    overrides: %{
      attributes: %{
        name: %{label: "Product Name", show_in_table?: true},
        price: %{formatter: &format_price/1},
        description: %{show_in_table?: false}
      },
      relationships: %{
        category: %{show_in_table?: true, display_field: :name}
      }
    }

  defp format_price(price) do
    "$#{:erlang.float_to_binary(price / 100, decimals: 2)}"
  end
end
```

### 3. Custom Components

```elixir
defmodule MyAppWeb.Admin.CustomUsersLive do
  use MyAppWeb, :live_view
  use AshComputer.LiveView

  use AshPanel.ComputerGenerator,
    resource: MyApp.Accounts.User,
    domain: MyApp.Accounts,
    views: [:list]

  use AshPanel.Computers.Filters,
    resource: MyApp.Accounts.User,
    fields: [:email, :role]

  # ...mount implementation...

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <!-- Use your custom table component -->
      <MyApp.CustomTable.render
        rows={@list_view_query_result}
        columns={@list_view_columns}
      />

      <!-- But keep default pagination -->
      <AshPanel.Components.DefaultPagination.render
        current_page={@list_view_page}
        total_pages={@list_view_total_pages}
        ...
      />
    </div>
    """
  end
end
```

## What Gets Generated

### List View Computer

**Assigns available in your view:**
- `@list_view_query_result` - The paginated records
- `@list_view_total_count` - Total number of records (filtered)
- `@list_view_total_pages` - Total pages
- `@list_view_page` - Current page
- `@list_view_page_size` - Items per page
- `@list_view_has_next_page` / `@list_view_has_prev_page`
- `@list_view_columns` - Column definitions
- `@list_view_sort_field` / `@list_view_sort_order`
- `@list_view_resource_schema` - Full ResourceSchema

**Events you can trigger:**
- `event(:list_view, :next_page)` - Next page
- `event(:list_view, :prev_page)` - Previous page
- `event(:list_view, :set_page)` - Jump to page (payload: %{"page" => "5"})
- `event(:list_view, :set_page_size)` - Change page size (payload: %{"page_size" => "25"})
- `event(:list_view, :set_sort)` - Change sort (payload: %{"field" => "email"})

### Detail View Computer

**Assigns available in your view:**
- `@detail_view_record` - The loaded record
- `@detail_view_loading?` - Whether loading
- `@detail_view_not_found?` - Whether record wasn't found
- `@detail_view_attributes` - Attributes to display
- `@detail_view_relationships` - Relationships to display
- `@detail_view_actions` - Available actions
- `@detail_view_show_modal` - Modal visibility state

**Events you can trigger:**
- `event(:detail_view, :select_record)` - Load record (payload: %{"id" => id})
- `event(:detail_view, :close)` - Close and clear
- `event(:detail_view, :refresh)` - Reload current record

### Form View Computer

**Assigns available in your view:**
- `@form_view_record` - Record being edited (nil for create)
- `@form_view_mode` - `:create` or `:update`
- `@form_view_fields` - Form field definitions with current values
- `@form_view_errors` - Validation errors
- `@form_view_submitting?` - Whether submitting
- `@form_view_success?` - Whether last submit succeeded
- `@form_view_show_form` - Form visibility state

**Events you can trigger:**
- `event(:form_view, :open_create)` - Open in create mode
- `event(:form_view, :open_edit)` - Open in edit mode (payload: %{"id" => id})
- `event(:form_view, :set_field)` - Update field (payload: %{"field" => "email", "value" => "..."})
- `event(:form_view, :submit)` - Submit form
- `event(:form_view, :close)` - Close form
- `event(:form_view, :reset)` - Reset to initial values

## Benefits

1. **Zero Configuration** - Just specify resource and domain
2. **Full CRUD** - All computers work together seamlessly
3. **Customizable** - Override any aspect via ResourceSchema
4. **Type Safe** - All generated from Ash resource definitions
5. **Reactive** - AshComputer handles all state automatically
6. **Composable** - Use default components or bring your own
