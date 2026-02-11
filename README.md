# AshPanel

A flexible, composable resource management UI library for Ash Framework applications.

## Features

- **Auto-discovery**: Automatically introspects Ash resources to generate complete admin interfaces
- **Reactive State**: Powered by AshComputer for clean, declarative reactive state management
- **Fully Customizable**: Swap out any component while maintaining the core logic
- **Authorization Aware**: Respects Ash policies and authorization rules
- **Composable**: Mix and match components, layouts, and views
- **Zero Config Start**: Get a full CRUD interface with minimal code

## Philosophy

**"Configuration by introspection, customization by composition"**

Start with zero configuration and progressively customize as needed.

## Quick Start

### Installation

Add `ash_panel` to your dependencies:

```elixir
def deps do
  [
    {:ash_panel, "~> 0.1.0"}
  ]
end
```

### Basic Usage

**Option 1: Using ResourceLive (Recommended)**

```elixir
# Create a LiveView module
defmodule MyAppWeb.Admin.UsersLive do
  use AshPanel.ResourceLive,
    resource: MyApp.Accounts.User,
    domain: MyApp.Accounts
end

# Mount in your router
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  use AshPanel.Router

  scope "/admin" do
    pipe_through [:browser, :require_authenticated_user]

    ash_panel_resource "/users", MyAppWeb.Admin.UsersLive
  end
end
```

This generates standard RESTful routes:
- `GET /admin/users` - List all users
- `GET /admin/users/new` - Create new user
- `GET /admin/users/:id` - View user details
- `GET /admin/users/:id/edit` - Edit user

**Option 2: Using Individual Views**

```elixir
defmodule MyAppWeb.Admin.UsersLive do
  use AshPanel.LiveView,
    resource: MyApp.Accounts.User,
    domain: MyApp.Accounts
end
```

Both options give you a full CRUD interface with:
- Pagination
- Filtering (auto-generated from resource attributes)
- Sorting
- Search
- Detail view
- Forms (create/edit)

See [ROUTER_EXAMPLE.md](ROUTER_EXAMPLE.md) for a complete multi-resource example.

## Customization

### Level 1: Configuration

```elixir
defmodule MyAppWeb.Admin.UsersLive do
  use AshPanel.LiveView,
    resource: MyApp.Accounts.User,
    domain: MyApp.Accounts,
    per_page: 25,
    searchable_fields: [:email, :name],
    default_sort: [inserted_at: :desc]

  # Override attribute display
  attribute :email do
    label "Email Address"
    sortable true
    filterable true
  end

  # Add custom actions
  action :send_welcome_email do
    label "Send Welcome"
    icon "mail"
    confirmation "Send welcome email?"
  end
end
```

### Level 2: Custom Components

```elixir
# Implement the behavior
defmodule MyApp.Components.CustomTable do
  @behaviour AshPanel.Components.TableBehavior
  use Phoenix.Component

  @impl true
  def render(assigns) do
    ~H"""
    <!-- Your custom table implementation -->
    """
  end
end

# Use it
defmodule MyAppWeb.Admin.UsersLive do
  use AshPanel.LiveView,
    resource: MyApp.Accounts.User,
    domain: MyApp.Accounts,
    components: [
      table: MyApp.Components.CustomTable
    ]
end
```

### Level 3: Custom Computers

```elixir
defmodule MyAppWeb.Admin.UsersLive do
  use AshPanel.LiveView,
    resource: MyApp.Accounts.User,
    domain: MyApp.Accounts

  # Extend the generated computer
  extend_computer :list_view do
    input :custom_filter do
      initial nil
    end

    val :custom_data do
      compute fn %{query_result: results} ->
        # Custom computation
      end
    end
  end
end
```

### Level 4: Completely Custom

```elixir
defmodule MyAppWeb.Admin.CustomUsersLive do
  use Phoenix.LiveView
  use AshPanel.Computers

  # Use just the computers, provide your own render
  def render(assigns) do
    ~H"""
    <!-- Completely custom layout -->
    """
  end
end
```

## Views and Layouts

AshPanel provides ready-to-use container components for common scenarios:

### Views

- `AshPanel.Views.ListView` - Complete list view with table, filters, and pagination
- `AshPanel.Views.DetailView` - Single record detail view with relationships
- `AshPanel.Views.FormView` - Create/update form with validation

### Layouts

- `AshPanel.Layouts.SidebarLayout` - Admin interface with sidebar navigation
- `AshPanel.Layouts.TopbarLayout` - Simple top navigation bar
- `AshPanel.Layouts.MinimalLayout` - Minimal layout for embedding

### Example

```elixir
def render(assigns) do
  ~H"""
  <AshPanel.Layouts.MinimalLayout.render
    title="User Management"
    actions={[%{label: "New User", on_click: "show_create_form", primary: true}]}
  >
    <AshPanel.Views.ListView.render
      rows={@list_view_rows}
      columns={@list_view_columns}
      current_page={@list_view_current_page}
      total_pages={@list_view_total_pages}
      on_row_click={&handle_row_click/1}
    />
  </AshPanel.Layouts.MinimalLayout.render>
  """
end
```

See [ZERO_CONFIG_EXAMPLE.md](ZERO_CONFIG_EXAMPLE.md) for a complete working example.

## Component Behaviors

AshPanel defines behaviors for all swappable components:

- `AshPanel.Components.TableBehavior` - Table/list rendering
- `AshPanel.Components.FilterBarBehavior` - Filter controls
- `AshPanel.Components.PaginationBehavior` - Pagination controls

Each behavior documents the expected assigns and contracts.

## Architecture

AshPanel separates concerns into four layers:

1. **Introspection Layer** - Auto-discovers resource metadata
2. **Computation Layer** - AshComputer-based reactive logic
3. **Configuration Layer** - DSL for customization
4. **Presentation Layer** - Pluggable UI components

This separation allows you to customize at any level without breaking the others.

## Comparison

| Feature | AshPanel | AshAdmin | Backpex |
|---------|----------|----------|---------|
| Auto-discovery | ✅ Full | ✅ Full | ⚠️ Manual |
| Customization | ✅ Excellent | ❌ Limited | ✅ Good |
| Reactive State | ✅ AshComputer | ❌ Manual | ❌ Manual |
| Component Swapping | ✅ Full | ❌ No | ✅ Yes |
| Dependencies | Phoenix LV | Phoenix LV | LV + DaisyUI + Alpine |

## Documentation

See the [full documentation](https://hexdocs.pm/ash_panel) for:
- Detailed guides
- Component reference
- Customization examples
- Migration guides

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
