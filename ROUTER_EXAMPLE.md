# Multi-Resource Admin with Router

This example shows how to create a complete admin interface managing multiple resources
using AshPanel's router helpers and navigation system.

## Step 1: Define Your Resources

Let's say you have these Ash resources:

```elixir
# lib/my_app/accounts/user.ex
defmodule MyApp.Accounts.User do
  use Ash.Resource, domain: MyApp.Accounts
  # ... attributes, actions, etc.
end

# lib/my_app/blog/post.ex
defmodule MyApp.Blog.Post do
  use Ash.Resource, domain: MyApp.Blog
  # ... attributes, actions, etc.
end

# lib/my_app/blog/comment.ex
defmodule MyApp.Blog.Comment do
  use Ash.Resource, domain: MyApp.Blog
  # ... attributes, actions, etc.
end
```

## Step 2: Create LiveView Modules

Create one LiveView per resource using `AshPanel.ResourceLive`:

```elixir
# lib/my_app_web/live/admin/users_live.ex
defmodule MyAppWeb.Admin.UsersLive do
  use AshPanel.ResourceLive,
    resource: MyApp.Accounts.User,
    domain: MyApp.Accounts,
    title: "User Management"
end

# lib/my_app_web/live/admin/posts_live.ex
defmodule MyAppWeb.Admin.PostsLive do
  use AshPanel.ResourceLive,
    resource: MyApp.Blog.Post,
    domain: MyApp.Blog,
    title: "Posts"
end

# lib/my_app_web/live/admin/comments_live.ex
defmodule MyAppWeb.Admin.CommentsLive do
  use AshPanel.ResourceLive,
    resource: MyApp.Blog.Comment,
    domain: MyApp.Blog,
    title: "Comments"
end
```

That's it! Each LiveView automatically handles index, show, new, and edit actions.

## Step 3: Mount Routes in Router

Use `ash_panel_resource` to mount all routes:

```elixir
# lib/my_app_web/router.ex
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  use AshPanel.Router

  # ... other pipelines ...

  scope "/admin", MyAppWeb.Admin do
    pipe_through [:browser, :require_authenticated_user]

    # Mount all resources
    ash_panel_resource "/users", UsersLive
    ash_panel_resource "/posts", PostsLive
    ash_panel_resource "/comments", CommentsLive, only: [:index, :show]
  end
end
```

This generates these routes:

```
GET /admin/users           UsersLive (live_action: :index)
GET /admin/users/new       UsersLive (live_action: :new)
GET /admin/users/:id       UsersLive (live_action: :show)
GET /admin/users/:id/edit  UsersLive (live_action: :edit)

GET /admin/posts           PostsLive (live_action: :index)
GET /admin/posts/new       PostsLive (live_action: :new)
GET /admin/posts/:id       PostsLive (live_action: :show)
GET /admin/posts/:id/edit  PostsLive (live_action: :edit)

GET /admin/comments        CommentsLive (live_action: :index)
GET /admin/comments/:id    CommentsLive (live_action: :show)
```

## Step 4: Add Navigation (Optional)

To add a sidebar with navigation between resources, create a custom layout:

```elixir
# lib/my_app_web/components/admin_layout.ex
defmodule MyAppWeb.Components.AdminLayout do
  use Phoenix.Component
  alias AshPanel.Navigation

  attr :current_user, :map, required: true
  attr :current_path, :string, required: true
  slot :inner_block, required: true

  def render(assigns) do
    # Define your resources for navigation
    assigns = assign(assigns, :resources, [
      %{
        resource: MyApp.Accounts.User,
        domain: MyApp.Accounts,
        label: "Users",
        path: "/admin/users",
        icon: "users",
        category: "Accounts"
      },
      %{
        resource: MyApp.Blog.Post,
        domain: MyApp.Blog,
        label: "Posts",
        path: "/admin/posts",
        icon: "document",
        category: "Content"
      },
      %{
        resource: MyApp.Blog.Comment,
        domain: MyApp.Blog,
        label: "Comments",
        path: "/admin/comments",
        icon: "chat",
        category: "Content"
      }
    ])

    assigns = assign(assigns, :menu_items, Navigation.menu_items(assigns.resources, assigns.current_path))
    assigns = assign(assigns, :grouped_menu, Navigation.grouped_menu(assigns.resources))

    ~H"""
    <div class="min-h-screen bg-gray-100">
      <!-- Sidebar -->
      <div class="hidden lg:fixed lg:inset-y-0 lg:flex lg:w-72 lg:flex-col">
        <div class="flex grow flex-col gap-y-5 overflow-y-auto border-r border-gray-200 bg-white px-6">
          <div class="flex h-16 shrink-0 items-center">
            <h1 class="text-xl font-bold text-gray-900">Admin Dashboard</h1>
          </div>

          <nav class="flex flex-1 flex-col">
            <ul role="list" class="flex flex-1 flex-col gap-y-7">
              <%= for {category, items} <- @grouped_menu do %>
                <li>
                  <div class="text-xs font-semibold leading-6 text-gray-400">{category}</div>
                  <ul role="list" class="-mx-2 mt-2 space-y-1">
                    <%= for item <- items do %>
                      <%
                        menu_item = Enum.find(@menu_items, fn m -> m.resource == item.resource end)
                      %>
                      <li>
                        <.link
                          href={menu_item.path}
                          class={menu_nav_class(menu_item.active?)}
                        >
                          {menu_item.label}
                        </.link>
                      </li>
                    <% end %>
                  </ul>
                </li>
              <% end %>
            </ul>
          </nav>
        </div>
      </div>

      <!-- Main content -->
      <div class="lg:pl-72">
        <div class="sticky top-0 z-40 flex h-16 shrink-0 items-center gap-x-4 border-b border-gray-200 bg-white px-4 shadow-sm sm:gap-x-6 sm:px-6 lg:px-8">
          <div class="flex flex-1 gap-x-4 self-stretch lg:gap-x-6">
            <div class="flex flex-1"></div>
            <div class="flex items-center gap-x-4 lg:gap-x-6">
              <span class="text-sm font-semibold text-gray-900">
                {@current_user.email}
              </span>
            </div>
          </div>
        </div>

        <main class="py-10">
          <div class="px-4 sm:px-6 lg:px-8">
            <%= render_slot(@inner_block) %>
          </div>
        </main>
      </div>
    </div>
    """
  end

  defp menu_nav_class(true) do
    "group flex gap-x-3 rounded-md bg-gray-50 p-2 text-sm font-semibold leading-6 text-indigo-600"
  end

  defp menu_nav_class(false) do
    "group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-700 hover:bg-gray-50 hover:text-indigo-600"
  end
end
```

## Step 5: Use Custom Layout in LiveViews

Update your LiveViews to use the custom layout:

```elixir
defmodule MyAppWeb.Admin.UsersLive do
  use AshPanel.ResourceLive,
    resource: MyApp.Accounts.User,
    domain: MyApp.Accounts,
    layout: MyAppWeb.Components.AdminLayout,
    title: "User Management"

  # Override render to use custom layout
  def render(assigns) do
    ~H"""
    <MyAppWeb.Components.AdminLayout.render
      current_user={@current_user}
      current_path={@current_path}
    >
      <%= super(assigns) %>
    </MyAppWeb.Components.AdminLayout.render>
    """
  end
end
```

## Complete Feature List

With this setup, you get:

### For Each Resource:

✅ **Index View (List)**
- Paginated table
- Auto-generated columns
- Filtering by all attributes
- Sorting
- Search
- Click row to view details

✅ **Show View (Detail)**
- All attributes displayed
- Related records shown
- Edit and delete buttons
- Back to list navigation

✅ **New View (Create Form)**
- All editable fields
- Validation
- Success/error messages
- Cancel button

✅ **Edit View (Update Form)**
- Pre-populated with current values
- Validation
- Success/error messages
- Cancel button

### Navigation:
✅ Sidebar with all resources
✅ Grouped by category
✅ Active state highlighting
✅ Breadcrumb navigation

### Authorization:
✅ Routes protected by authentication
✅ Respects Ash policies
✅ Actor passed to all queries

## Customization Examples

### Custom Page Size

```elixir
defmodule MyAppWeb.Admin.UsersLive do
  use AshPanel.ResourceLive,
    resource: MyApp.Accounts.User,
    domain: MyApp.Accounts

  # Override to change default page size
  def handle_params(params, url, socket) do
    socket =
      socket
      |> assign(:list_view_page_size, 50)  # Custom page size

    super(params, url, socket)
  end
end
```

### Add Custom Actions

```elixir
defmodule MyAppWeb.Admin.UsersLive do
  use AshPanel.ResourceLive,
    resource: MyApp.Accounts.User,
    domain: MyApp.Accounts

  # Override page_actions to add custom buttons
  defp page_actions(:index) do
    [
      %{
        label: "Export Users",
        on_click: "export_users",
        primary: false
      },
      %{
        label: "New User",
        on_click: JS.patch("/admin/users/new"),
        primary: true
      }
    ]
  end

  defp page_actions(_), do: super()

  # Handle custom action
  def handle_event("export_users", _params, socket) do
    # Export logic here
    {:noreply, socket}
  end
end
```

### Custom Field Rendering

```elixir
defmodule MyAppWeb.Admin.UsersLive do
  use AshPanel.ResourceLive,
    resource: MyApp.Accounts.User,
    domain: MyApp.Accounts

  # Override render to customize form fields
  def render(assigns) do
    ~H"""
    <%= case @live_action do %>
      <% :new -> %>
        <AshPanel.Views.FormView.render
          {assigns_to_attributes(@assigns, :form_view)}
          field_components=%{
            profile_photo: &MyApp.Components.ImageUploader.render/1,
            bio: &MyApp.Components.RichTextEditor.render/1
          }
        />
      <% _ -> %>
        <%= super(assigns) %>
    <% end %>
    """
  end
end
```

## Summary

With AshPanel's router integration, you can:

1. Create a LiveView per resource (3 lines of code)
2. Mount all routes with `ash_panel_resource` (1 line per resource)
3. Get complete CRUD interface automatically
4. Add navigation with the Navigation module
5. Customize anything as needed

Total code for a complete admin interface: **~30 lines** for 3 resources with navigation!
