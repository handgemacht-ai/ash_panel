# Zero-Config Example

This example demonstrates how to create a fully functional admin interface for an Ash resource with minimal code.

## The Resource

Let's say you have a User resource:

```elixir
defmodule MyApp.Accounts.User do
  use Ash.Resource,
    domain: MyApp.Accounts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "users"
    repo MyApp.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :string do
      allow_nil? false
      public? true
    end

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :role, :atom do
      constraints one_of: [:admin, :user, :moderator]
      default :user
      public? true
    end

    attribute :active, :boolean do
      default true
      public? true
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:email, :name, :role, :active]
    end

    update :update do
      accept [:email, :name, :role, :active]
    end
  end

  relationships do
    has_many :posts, MyApp.Blog.Post
    belongs_to :organization, MyApp.Accounts.Organization
  end
end
```

## Step 1: Create the LiveView

Create a new LiveView at `lib/my_app_web/live/admin/users_live.ex`:

```elixir
defmodule MyAppWeb.Admin.UsersLive do
  use MyAppWeb, :live_view
  use AshPanel.LiveView,
    resource: MyApp.Accounts.User,
    domain: MyApp.Accounts,
    views: [:list, :detail, :form]

  def mount(_params, _session, socket) do
    {:ok, socket |> setup_ash_panel(actor: socket.assigns.current_user)}
  end

  def render(assigns) do
    ~H"""
    <AshPanel.Layouts.MinimalLayout.render
      title="User Management"
      subtitle="Manage all users in your system"
      actions={[
        %{label: "New User", on_click: "show_create_form", primary: true}
      ]}
    >
      <!-- List View -->
      <div :if={!@showing_detail && !@showing_form}>
        <AshPanel.Views.ListView.render
          rows={@list_view_rows}
          columns={@list_view_columns}
          current_page={@list_view_current_page}
          total_pages={@list_view_total_pages}
          has_next={@list_view_has_next_page}
          has_prev={@list_view_has_prev_page}
          filter_definitions={@list_view_filter_definitions}
          filter_values={@list_view_filter_values}
          filter_count={@list_view_filter_count}
          sort_field={@list_view_sort_field}
          sort_order={@list_view_sort_order}
          loading?={@list_view_loading}
          on_row_click={&handle_row_click/1}
          on_sort={event(:list_view, :set_sort)}
          on_filter_change={event(:list_view, :set_filter)}
          on_clear_filters={event(:list_view, :clear_all_filters)}
          on_next_page={event(:list_view, :next_page)}
          on_prev_page={event(:list_view, :prev_page)}
          on_page_size_change={event(:list_view, :set_page_size)}
        />
      </div>

      <!-- Detail View Modal -->
      <.modal :if={@showing_detail} id="detail-modal" on_cancel={&handle_close_detail/0}>
        <AshPanel.Views.DetailView.render
          record={@detail_view_record}
          attributes={@detail_view_attributes}
          relationships={@detail_view_relationships}
          actions={@detail_view_actions}
          loading?={@detail_view_loading}
          not_found?={@detail_view_not_found}
          error?={@detail_view_error}
          on_action={&handle_detail_action/1}
        />
      </.modal>

      <!-- Form View Modal -->
      <.modal :if={@showing_form} id="form-modal" on_cancel={&handle_close_form/0}>
        <AshPanel.Views.FormView.render
          mode={@form_view_mode}
          form_data={@form_view_form_data}
          errors={@form_view_errors}
          submitting?={@form_view_submitting}
          success?={@form_view_success}
          attributes={@form_view_attributes}
          relationships={@form_view_relationships}
          on_change={event(:form_view, :update_field)}
          on_submit={event(:form_view, :submit)}
          on_cancel={&handle_close_form/0}
        />
      </.modal>
    </AshPanel.Layouts.MinimalLayout.render>
    """
  end

  # Track which view is showing
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:showing_detail, false)
      |> assign(:showing_form, false)
      |> setup_ash_panel(actor: socket.assigns.current_user)

    {:ok, socket}
  end

  # Handle row clicks to show detail
  def handle_event("row_click", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> assign(:showing_detail, true)
     |> show_detail(id)}
  end

  # Handle showing create form
  def handle_event("show_create_form", _params, socket) do
    {:noreply,
     socket
     |> assign(:showing_form, true)
     |> show_create_form()}
  end

  # Handle detail actions
  def handle_event("detail_action", %{"action" => "edit"}, socket) do
    record_id = socket.assigns.detail_view_record.id

    {:noreply,
     socket
     |> assign(:showing_detail, false)
     |> assign(:showing_form, true)
     |> show_edit_form(record_id)}
  end

  def handle_event("detail_action", %{"action" => "delete"}, socket) do
    # Handle delete action
    # After successful delete, close detail and refresh list
    {:noreply,
     socket
     |> assign(:showing_detail, false)
     |> refresh_list()}
  end

  # Close handlers
  defp handle_close_detail(socket) do
    assign(socket, :showing_detail, false)
  end

  defp handle_close_form(socket) do
    socket =
      socket
      |> assign(:showing_form, false)

    # Refresh list after form submission
    if socket.assigns.form_view_success do
      refresh_list(socket)
    else
      socket
    end
  end

  defp handle_row_click(%{"id" => id}) do
    "row_click"
  end

  defp handle_detail_action(%{"action" => action}) do
    "detail_action"
  end
end
```

## Step 2: Add Route

In your `router.ex`:

```elixir
scope "/admin", MyAppWeb.Admin do
  pipe_through [:browser, :require_authenticated_user]

  live "/users", UsersLive
end
```

## That's It!

You now have a fully functional admin interface with:

- ✅ Paginated table with all user attributes
- ✅ Automatic filtering based on attribute types
- ✅ Sortable columns
- ✅ Detail view with all attributes and relationships
- ✅ Create form with all editable fields
- ✅ Update form with validation
- ✅ Delete action with confirmation
- ✅ Automatic field type detection
- ✅ Relationship display
- ✅ Loading states
- ✅ Error handling

## What AshPanel Auto-Detected

From your User resource, AshPanel automatically:

1. **Detected filterable fields**: email, name, role, active
2. **Inferred filter types**:
   - email: text search
   - name: text search
   - role: select dropdown with options
   - active: boolean toggle
3. **Determined sortable columns**: All except relationships
4. **Identified display field**: name (from common field names)
5. **Built form fields**:
   - email: text input (required)
   - name: text input (required)
   - role: select dropdown with options
   - active: checkbox
6. **Loaded relationships**: posts, organization
7. **Generated actions**: Create, Update, Delete based on your action definitions
8. **Set up validation**: Based on allow_nil? and constraints

## Customization

If you want to customize any of this, you can provide overrides:

```elixir
use AshPanel.LiveView,
  resource: MyApp.Accounts.User,
  domain: MyApp.Accounts,
  views: [:list, :detail, :form],
  list_view: [
    # Custom default sort
    default_sort: [inserted_at: :desc],

    # Custom page size
    default_page_size: 50,

    # Override specific column labels
    column_overrides: %{
      email: %{label: "Email Address"},
      inserted_at: %{label: "Joined"}
    },

    # Custom filter definitions
    filter_definitions: [
      %{field: :role, type: :select, options: [
        %{value: "admin", label: "Administrator"},
        %{value: "user", label: "Regular User"},
        %{value: "moderator", label: "Moderator"}
      ]},
      %{field: :email, type: :search, placeholder: "Search by email..."}
    ]
  ],
  detail_view: [
    # Always preload these relationships
    preload: [:posts, :organization],

    # Use two-column layout
    layout: :two_column
  ],
  form_view: [
    # Custom field order
    field_order: [:name, :email, :role, :organization, :active],

    # Custom validation messages
    validation_messages: %{
      email: "Please enter a valid email address"
    }
  ]
```

## Multiple Resources

To manage multiple resources, create separate LiveViews for each:

```elixir
# lib/my_app_web/live/admin/users_live.ex
defmodule MyAppWeb.Admin.UsersLive do
  use AshPanel.LiveView,
    resource: MyApp.Accounts.User,
    domain: MyApp.Accounts
  # ...
end

# lib/my_app_web/live/admin/posts_live.ex
defmodule MyAppWeb.Admin.PostsLive do
  use AshPanel.LiveView,
    resource: MyApp.Blog.Post,
    domain: MyApp.Blog
  # ...
end
```

Then use a layout to navigate between them:

```elixir
def render(assigns) do
  ~H"""
  <AshPanel.Layouts.SidebarLayout.render
    title="Admin Dashboard"
    resources={[
      %{resource: MyApp.Accounts.User, plural_name: "Users"},
      %{resource: MyApp.Blog.Post, plural_name: "Posts"}
    ]}
    current_resource={@current_resource}
    user={@current_user}
    on_resource_select={&handle_resource_select/1}
  >
    <!-- Your content -->
  </AshPanel.Layouts.SidebarLayout.render>
  """
end
```
