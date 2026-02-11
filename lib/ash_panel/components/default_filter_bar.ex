defmodule AshPanel.Components.DefaultFilterBar do
  @moduledoc """
  Default filter bar component implementation.

  Implements `AshPanel.Components.FilterBarBehavior` with Tailwind CSS styling.
  Renders a horizontal bar of filter inputs based on filter definitions.
  """

  @behaviour AshPanel.Components.FilterBarBehavior

  use Phoenix.Component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex gap-4 items-end flex-wrap">
      <div :for={definition <- @definitions} class="flex-1 min-w-[200px]">
        <%= render_filter_control(definition, @values, @on_change) %>
      </div>
    </div>

    <!-- Filter chips -->
    <div :if={Map.get(assigns, :active_count, 0) > 0} class="flex items-center gap-2 mt-4">
      <span class="text-sm text-gray-700">
        {@active_count} {if @active_count == 1, do: "filter", else: "filters"} active
      </span>
      <button
        :if={Map.get(assigns, :on_clear)}
        type="button"
        phx-click={@on_clear}
        class="inline-flex items-center px-2.5 py-1.5 border border-gray-300 shadow-sm text-xs font-medium rounded text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
      >
        Clear all
      </button>
    </div>
    """
  end

  # Private helpers

  defp render_filter_control(definition, values, on_change) do
    case definition.type do
      :search -> search_filter(definition, values, on_change)
      :select -> select_filter(definition, values, on_change)
      :number -> number_filter(definition, values, on_change)
      :boolean -> boolean_filter(definition, values, on_change)
      _ -> search_filter(definition, values, on_change)
    end
  end

  defp search_filter(definition, values, on_change) do
    assigns = %{
      definition: definition,
      value: Map.get(values, definition.field),
      on_change: on_change,
      id: "filter-#{definition.field}"
    }

    ~H"""
    <div>
      <label for={@id} class="block text-sm font-medium text-gray-700">
        {@definition.label}
      </label>
      <form phx-change={@on_change}>
        <input type="hidden" name="field" value={@definition.field} />
        <input
          type="text"
          id={@id}
          name="value"
          value={@value || ""}
          phx-debounce="300"
          class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          placeholder={@definition.placeholder}
        />
      </form>
    </div>
    """
  end

  defp select_filter(definition, values, on_change) do
    assigns = %{
      definition: definition,
      value: Map.get(values, definition.field),
      on_change: on_change,
      id: "filter-#{definition.field}"
    }

    ~H"""
    <div>
      <label for={@id} class="block text-sm font-medium text-gray-700">
        {@definition.label}
      </label>
      <form phx-change={@on_change}>
        <input type="hidden" name="field" value={@definition.field} />
        <select
          id={@id}
          name="value"
          class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
        >
          <option value="" selected={@value == nil || @value == ""}>
            {@definition.placeholder}
          </option>
          <option :for={opt <- @definition.options || []} value={opt} selected={@value == opt}>
            {opt |> to_string() |> String.capitalize()}
          </option>
        </select>
      </form>
    </div>
    """
  end

  defp number_filter(definition, values, on_change) do
    assigns = %{
      definition: definition,
      value: Map.get(values, definition.field),
      on_change: on_change,
      id: "filter-#{definition.field}"
    }

    ~H"""
    <div>
      <label for={@id} class="block text-sm font-medium text-gray-700">
        {@definition.label}
      </label>
      <form phx-change={@on_change}>
        <input type="hidden" name="field" value={@definition.field} />
        <input
          type="number"
          id={@id}
          name="value"
          value={@value || ""}
          min="0"
          phx-debounce="300"
          class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          placeholder={@definition.placeholder}
        />
      </form>
    </div>
    """
  end

  defp boolean_filter(definition, values, on_change) do
    assigns = %{
      definition: definition,
      value: Map.get(values, definition.field),
      on_change: on_change,
      id: "filter-#{definition.field}"
    }

    ~H"""
    <div>
      <label for={@id} class="block text-sm font-medium text-gray-700">
        {@definition.label}
      </label>
      <form phx-change={@on_change}>
        <input type="hidden" name="field" value={@definition.field} />
        <select
          id={@id}
          name="value"
          class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
        >
          <option value="" selected={@value == nil}>All</option>
          <option value="true" selected={@value == true}>Yes</option>
          <option value="false" selected={@value == false}>No</option>
        </select>
      </form>
    </div>
    """
  end
end
