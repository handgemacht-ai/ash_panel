defmodule AshPanel.Components.DefaultPageSizeSelector do
  @moduledoc """
  Default page size selector component.

  A small dropdown that allows users to change the number of items displayed per page.
  """

  use Phoenix.Component

  @doc """
  Renders a page size selector dropdown.

  ## Attributes

  - `current_size` - The current page size (required)
  - `on_change` - The event to trigger on change (required)
  - `options` - List of page size options (default: [10, 25, 50])
  - `id` - Element ID (default: "page-size-selector")

  ## Examples

      <.page_size_selector
        current_size={@page_size}
        on_change={event(:list_view, :set_page_size)}
      />

      <.page_size_selector
        current_size={@page_size}
        on_change={event(:list_view, :set_page_size)}
        options={[5, 10, 20, 50, 100]}
      />
  """
  attr(:current_size, :integer, required: true)
  attr(:on_change, :string, required: true)
  attr(:options, :list, default: [10, 25, 50])
  attr(:id, :string, default: "page-size-selector")

  def render(assigns) do
    ~H"""
    <select
      id={@id}
      class="block rounded-md border-0 py-1.5 pl-3 pr-10 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-indigo-600 sm:text-sm sm:leading-6"
      phx-change={@on_change}
      name="page_size"
    >
      <option :for={size <- @options} value={size} selected={@current_size == size}>
        {size} per page
      </option>
    </select>
    """
  end
end
