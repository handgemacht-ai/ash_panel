defmodule AshPanel.Layouts.SidebarLayout do
  @moduledoc """
  A layout with a sidebar navigation and main content area.

  Perfect for admin interfaces or resource management dashboards with
  multiple resources to navigate between.

  ## Usage

      <AshPanel.Layouts.SidebarLayout.render
        title="Admin Dashboard"
        resources={@resources}
        current_resource={@current_resource}
        user={@current_user}
        on_resource_select={&handle_resource_select/1}
        on_logout={&handle_logout/0}
      >
        <!-- Your content here -->
        <AshPanel.Views.ListView.render ... />
      </AshPanel.Layouts.SidebarLayout.render>

  ## Customization

  You can customize the sidebar by providing:
  - Custom logo component
  - Additional navigation items
  - User menu items
  - Mobile menu behavior
  """

  use Phoenix.Component

  attr(:title, :string, required: true, doc: "Page title")
  attr(:resources, :list, default: [], doc: "List of ResourceSchema structs for navigation")
  attr(:current_resource, :any, default: nil, doc: "Currently selected resource module")
  attr(:user, :map, default: nil, doc: "Current user for user menu")
  attr(:logo_component, :any, default: nil, doc: "Custom logo component")
  attr(:show_user_menu?, :boolean, default: true, doc: "Show user menu in header")
  attr(:on_resource_select, :any, default: nil, doc: "Callback when resource is selected")
  attr(:on_logout, :any, default: nil, doc: "Callback for logout action")
  slot(:inner_block, required: true)

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-100">
      <!-- Sidebar for desktop -->
      <div class="hidden lg:fixed lg:inset-y-0 lg:z-50 lg:flex lg:w-72 lg:flex-col">
        <div class="flex grow flex-col gap-y-5 overflow-y-auto border-r border-gray-200 bg-white px-6">
          <div class="flex h-16 shrink-0 items-center">
            <%= if @logo_component do %>
              <%= render_slot(@logo_component) %>
            <% else %>
              <h1 class="text-xl font-bold text-gray-900">{@title}</h1>
            <% end %>
          </div>

          <nav class="flex flex-1 flex-col">
            <ul role="list" class="flex flex-1 flex-col gap-y-7">
              <li>
                <ul role="list" class="-mx-2 space-y-1">
                  <%= for resource <- @resources do %>
                    <li>
                      <button
                        type="button"
                        phx-click={@on_resource_select}
                        phx-value-resource={resource.resource}
                        class={resource_nav_class(resource.resource == @current_resource)}
                      >
                        {resource.plural_name}
                      </button>
                    </li>
                  <% end %>
                </ul>
              </li>
            </ul>
          </nav>
        </div>
      </div>

      <!-- Main content area -->
      <div class="lg:pl-72">
        <!-- Top navigation -->
        <div class="sticky top-0 z-40 flex h-16 shrink-0 items-center gap-x-4 border-b border-gray-200 bg-white px-4 shadow-sm sm:gap-x-6 sm:px-6 lg:px-8">
          <!-- Mobile menu button -->
          <button
            type="button"
            class="-m-2.5 p-2.5 text-gray-700 lg:hidden"
            phx-click="toggle_mobile_menu"
          >
            <span class="sr-only">Open sidebar</span>
            <svg
              class="h-6 w-6"
              fill="none"
              viewBox="0 0 24 24"
              stroke-width="1.5"
              stroke="currentColor"
              aria-hidden="true"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"
              />
            </svg>
          </button>

          <!-- Separator -->
          <div class="h-6 w-px bg-gray-200 lg:hidden" aria-hidden="true"></div>

          <div class="flex flex-1 gap-x-4 self-stretch lg:gap-x-6">
            <div class="flex flex-1"></div>

            <!-- User menu -->
            <%= if @show_user_menu? && @user do %>
              <div class="flex items-center gap-x-4 lg:gap-x-6">
                <div class="hidden lg:block lg:h-6 lg:w-px lg:bg-gray-200" aria-hidden="true">
                </div>

                <!-- Profile dropdown -->
                <div class="relative">
                  <button
                    type="button"
                    class="-m-1.5 flex items-center p-1.5"
                    phx-click="toggle_user_menu"
                  >
                    <span class="sr-only">Open user menu</span>
                    <div class="h-8 w-8 rounded-full bg-gray-200 flex items-center justify-center">
                      <span class="text-sm font-medium text-gray-600">
                        {user_initials(@user)}
                      </span>
                    </div>
                    <span class="hidden lg:flex lg:items-center">
                      <span class="ml-4 text-sm font-semibold leading-6 text-gray-900">
                        {user_display_name(@user)}
                      </span>
                    </span>
                  </button>
                </div>
              </div>
            <% end %>
          </div>
        </div>

        <!-- Page content -->
        <main class="py-10">
          <div class="px-4 sm:px-6 lg:px-8">
            <%= render_slot(@inner_block) %>
          </div>
        </main>
      </div>
    </div>
    """
  end

  defp resource_nav_class(true) do
    "group flex gap-x-3 rounded-md bg-gray-50 p-2 text-sm font-semibold leading-6 text-indigo-600 w-full text-left"
  end

  defp resource_nav_class(false) do
    "group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-700 hover:bg-gray-50 hover:text-indigo-600 w-full text-left"
  end

  defp user_initials(%{name: name}) when is_binary(name) do
    name
    |> String.split()
    |> Enum.take(2)
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.upcase()
  end

  defp user_initials(%{email: email}) when is_binary(email) do
    email
    |> String.first()
    |> String.upcase()
  end

  defp user_initials(_), do: "U"

  defp user_display_name(%{name: name}) when is_binary(name), do: name
  defp user_display_name(%{email: email}) when is_binary(email), do: email
  defp user_display_name(_), do: "User"
end
