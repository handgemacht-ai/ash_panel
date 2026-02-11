defmodule AshPanel.Layouts.MinimalLayout do
  @moduledoc """
  A minimal layout with just a simple header and content area.

  Perfect for embedding resource management into existing pages or
  when you want to handle navigation yourself.

  ## Usage

      <AshPanel.Layouts.MinimalLayout.render
        title="User Management"
        breadcrumbs={[
          %{label: "Home", href: "/"},
          %{label: "Users", href: nil}
        ]}
      >
        <!-- Your content here -->
        <AshPanel.Views.ListView.render ... />
      </AshPanel.Layouts.MinimalLayout.render>
  """

  use Phoenix.Component

  attr(:title, :string, default: nil, doc: "Page title")
  attr(:subtitle, :string, default: nil, doc: "Page subtitle/description")
  attr(:breadcrumbs, :list, default: [], doc: "Breadcrumb navigation")
  attr(:show_header?, :boolean, default: true, doc: "Show header section")
  attr(:actions, :list, default: [], doc: "Action buttons in header")
  slot(:inner_block, required: true)

  def render(assigns) do
    ~H"""
    <div class="ash-panel-minimal-layout">
      <%= if @show_header? && (@title || @subtitle || length(@breadcrumbs) > 0 || length(@actions) > 0) do %>
        <div class="mb-8">
          <!-- Breadcrumbs -->
          <%= if length(@breadcrumbs) > 0 do %>
            <nav class="flex mb-4" aria-label="Breadcrumb">
              <ol role="list" class="flex items-center space-x-2">
                <%= for {crumb, idx} <- Enum.with_index(@breadcrumbs) do %>
                  <li class="flex items-center">
                    <%= if idx > 0 do %>
                      <svg
                        class="h-5 w-5 flex-shrink-0 text-gray-400 mr-2"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                        aria-hidden="true"
                      >
                        <path
                          fill-rule="evenodd"
                          d="M7.21 14.77a.75.75 0 01.02-1.06L11.168 10 7.23 6.29a.75.75 0 111.04-1.08l4.5 4.25a.75.75 0 010 1.08l-4.5 4.25a.75.75 0 01-1.06-.02z"
                          clip-rule="evenodd"
                        />
                      </svg>
                    <% end %>

                    <%= if crumb[:href] do %>
                      <a
                        href={crumb.href}
                        class="text-sm font-medium text-gray-500 hover:text-gray-700"
                      >
                        {crumb.label}
                      </a>
                    <% else %>
                      <span class="text-sm font-medium text-gray-900">{crumb.label}</span>
                    <% end %>
                  </li>
                <% end %>
              </ol>
            </nav>
          <% end %>

          <!-- Title and actions -->
          <div class="md:flex md:items-center md:justify-between">
            <div class="min-w-0 flex-1">
              <%= if @title do %>
                <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:truncate sm:text-3xl sm:tracking-tight">
                  {@title}
                </h2>
              <% end %>

              <%= if @subtitle do %>
                <p class="mt-2 text-sm text-gray-700">
                  {@subtitle}
                </p>
              <% end %>
            </div>

            <%= if length(@actions) > 0 do %>
              <div class="mt-4 flex md:ml-4 md:mt-0 gap-x-3">
                <%= for action <- @actions do %>
                  <button
                    type="button"
                    phx-click={action.on_click}
                    class={action_button_class(action)}
                  >
                    {action.label}
                  </button>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>

      <!-- Main content -->
      <div class="ash-panel-content">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  defp action_button_class(%{primary: true}) do
    "inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
  end

  defp action_button_class(_action) do
    "inline-flex items-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
  end
end
