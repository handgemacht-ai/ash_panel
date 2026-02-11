defmodule AshPanel.Layouts.TopbarLayout do
  @moduledoc """
  A layout with a top navigation bar and main content area.

  Simpler than sidebar layout, good for single-resource interfaces or
  when you want a more compact navigation.

  ## Usage

      <AshPanel.Layouts.TopbarLayout.render
        title="User Management"
        tabs={[
          %{label: "Users", value: "users", current: true},
          %{label: "Settings", value: "settings", current: false}
        ]}
        on_tab_select={&handle_tab_select/1}
        user={@current_user}
      >
        <!-- Your content here -->
        <AshPanel.Views.ListView.render ... />
      </AshPanel.Layouts.TopbarLayout.render>
  """

  use Phoenix.Component

  attr(:title, :string, required: true, doc: "Page title")
  attr(:tabs, :list, default: [], doc: "Navigation tabs")
  attr(:user, :map, default: nil, doc: "Current user")
  attr(:show_user_menu?, :boolean, default: true, doc: "Show user menu")
  attr(:on_tab_select, :any, default: nil, doc: "Tab selection callback")
  attr(:actions, :list, default: [], doc: "Action buttons in header")
  slot(:inner_block, required: true)

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-100">
      <!-- Top navigation bar -->
      <header class="bg-white shadow-sm">
        <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div class="flex h-16 items-center justify-between">
            <!-- Title -->
            <div class="flex items-center">
              <h1 class="text-2xl font-bold leading-7 text-gray-900 sm:truncate sm:text-3xl sm:tracking-tight">
                {@title}
              </h1>
            </div>

            <!-- Actions and user menu -->
            <div class="flex items-center gap-x-4">
              <%= for action <- @actions do %>
                <button
                  type="button"
                  phx-click={action.on_click}
                  class="inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                >
                  {action.label}
                </button>
              <% end %>

              <%= if @show_user_menu? && @user do %>
                <div class="relative ml-4">
                  <button
                    type="button"
                    class="flex items-center gap-x-2"
                    phx-click="toggle_user_menu"
                  >
                    <div class="h-8 w-8 rounded-full bg-gray-200 flex items-center justify-center">
                      <span class="text-sm font-medium text-gray-600">
                        {user_initials(@user)}
                      </span>
                    </div>
                  </button>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Tabs -->
          <%= if length(@tabs) > 0 do %>
            <div class="border-t border-gray-200">
              <nav class="-mb-px flex space-x-8" aria-label="Tabs">
                <%= for tab <- @tabs do %>
                  <button
                    type="button"
                    phx-click={@on_tab_select}
                    phx-value-tab={tab.value}
                    class={tab_class(tab.current)}
                  >
                    {tab.label}
                  </button>
                <% end %>
              </nav>
            </div>
          <% end %>
        </div>
      </header>

      <!-- Main content -->
      <main>
        <div class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
          <%= render_slot(@inner_block) %>
        </div>
      </main>
    </div>
    """
  end

  defp tab_class(true) do
    "border-indigo-500 text-indigo-600 whitespace-nowrap border-b-2 py-4 px-1 text-sm font-medium"
  end

  defp tab_class(false) do
    "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 whitespace-nowrap border-b-2 py-4 px-1 text-sm font-medium"
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
end
