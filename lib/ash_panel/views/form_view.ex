defmodule AshPanel.Views.FormView do
  @moduledoc """
  Complete form view that handles both create and update forms.

  This is a container component that renders a form with all necessary fields,
  validation errors, and submit actions based on the resource schema.

  ## Usage

      <AshPanel.Views.FormView.render
        mode={@form_view_mode}
        form_data={@form_view_form_data}
        errors={@form_view_errors}
        submitting?={@form_view_submitting?}
        success?={@form_view_success?}
        attributes={@form_view_attributes}
        relationships={@form_view_relationships}
        on_change={event(:form_view, :update_field)}
        on_submit={event(:form_view, :submit)}
        on_cancel={&handle_cancel/0}
      />

  ## Form Data Structure

  The form_data map should contain values keyed by field name:

      %{
        name: "John Doe",
        email: "john@example.com",
        age: 30,
        active: true
      }

  ## Custom Field Components

  You can provide custom components for specific fields:

      <AshPanel.Views.FormView.render
        ...
        field_components=%{
          bio: &MyApp.Components.RichTextEditor.render/1,
          profile_photo: &MyApp.Components.ImageUploader.render/1
        }
      />
  """

  use Phoenix.Component

  @doc """
  Renders a form view for creating or updating a record.
  """
  def render(assigns) do
    assigns =
      assigns
      |> Map.put_new(:field_components, %{})
      |> Map.put_new(:show_cancel?, true)
      |> Map.put_new(:cancel_text, "Cancel")
      |> Map.put_new(:layout, :single_column)

    ~H"""
    <div class="ash-panel-form-view">
      <%= if @success? do %>
        <div class="rounded-md bg-green-50 p-4 mb-4">
          <div class="flex">
            <div class="flex-shrink-0">
              <svg
                class="h-5 w-5 text-green-400"
                viewBox="0 0 20 20"
                fill="currentColor"
                aria-hidden="true"
              >
                <path
                  fill-rule="evenodd"
                  d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z"
                  clip-rule="evenodd"
                />
              </svg>
            </div>
            <div class="ml-3">
              <p class="text-sm font-medium text-green-800">
                {success_message(@mode)}
              </p>
            </div>
          </div>
        </div>
      <% end %>

      <form phx-submit={@on_submit} phx-change={@on_change} class="space-y-6">
        <div class={form_grid_class(@layout)}>
          <%= for attr <- @attributes do %>
            <%= if attr.show_in_form? do %>
              <.form_field
                attribute={attr}
                value={Map.get(@form_data, attr.name)}
                error={get_field_error(@errors, attr.name)}
                disabled={@submitting?}
                custom_component={Map.get(@field_components, attr.name)}
              />
            <% end %>
          <% end %>

          <%= for rel <- @relationships do %>
            <%= if rel.show_in_form? do %>
              <.relationship_field
                relationship={rel}
                value={Map.get(@form_data, rel.name)}
                error={get_field_error(@errors, rel.name)}
                disabled={@submitting?}
              />
            <% end %>
          <% end %>
        </div>

        <%= if map_size(@errors) > 0 do %>
          <div class="rounded-md bg-red-50 p-4">
            <div class="flex">
              <div class="flex-shrink-0">
                <svg
                  class="h-5 w-5 text-red-400"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                  aria-hidden="true"
                >
                  <path
                    fill-rule="evenodd"
                    d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z"
                    clip-rule="evenodd"
                  />
                </svg>
              </div>
              <div class="ml-3">
                <h3 class="text-sm font-medium text-red-800">
                  There {if map_size(@errors) == 1, do: "is", else: "are"} {map_size(@errors)} error{if map_size(@errors) > 1, do: "s"} with your submission
                </h3>
              </div>
            </div>
          </div>
        <% end %>

        <div class="flex items-center justify-end gap-x-3 pt-4 border-t border-gray-200">
          <%= if @show_cancel? do %>
            <button
              type="button"
              phx-click={@on_cancel}
              disabled={@submitting?}
              class="rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {@cancel_text}
            </button>
          <% end %>

          <button
            type="submit"
            disabled={@submitting?}
            class="inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <%= if @submitting? do %>
              <svg
                class="animate-spin -ml-1 mr-2 h-4 w-4 text-white"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
              >
                <circle
                  class="opacity-25"
                  cx="12"
                  cy="12"
                  r="10"
                  stroke="currentColor"
                  stroke-width="4"
                >
                </circle>
                <path
                  class="opacity-75"
                  fill="currentColor"
                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                >
                </path>
              </svg>
              Submitting...
            <% else %>
              {submit_button_text(@mode)}
            <% end %>
          </button>
        </div>
      </form>
    </div>
    """
  end

  defp form_field(assigns) do
    ~H"""
    <div class="form-field">
      <label for={field_id(@attribute)} class="block text-sm font-medium leading-6 text-gray-900">
        {@attribute.label}
        <%= if AshPanel.Schema.AttributeSchema.required?(@attribute) do %>
          <span class="text-red-500">*</span>
        <% end %>
      </label>

      <div class="mt-2">
        <%= if @custom_component do %>
          <%= @custom_component.(%{
            attribute: @attribute,
            value: @value,
            error: @error,
            disabled: @disabled
          }) %>
        <% else %>
          <.field_input attribute={@attribute} value={@value} disabled={@disabled} />
        <% end %>
      </div>

      <%= if @error do %>
        <p class="mt-2 text-sm text-red-600" id={"#{field_id(@attribute)}-error"}>
          {@error}
        </p>
      <% end %>

      <%= if @attribute.description do %>
        <p class="mt-2 text-sm text-gray-500">
          {@attribute.description}
        </p>
      <% end %>
    </div>
    """
  end

  defp field_input(assigns) do
    ~H"""
    <%= case @attribute.field_type do %>
      <% :text_input -> %>
        <input
          type="text"
          id={field_id(@attribute)}
          name={"field[#{@attribute.name}]"}
          value={@value || ""}
          disabled={@disabled}
          class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6 disabled:bg-gray-50 disabled:text-gray-500"
        />
      <% :number_input -> %>
        <input
          type="number"
          id={field_id(@attribute)}
          name={"field[#{@attribute.name}]"}
          value={@value || ""}
          disabled={@disabled}
          class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6 disabled:bg-gray-50 disabled:text-gray-500"
        />
      <% :textarea -> %>
        <textarea
          id={field_id(@attribute)}
          name={"field[#{@attribute.name}]"}
          rows="3"
          disabled={@disabled}
          class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6 disabled:bg-gray-50 disabled:text-gray-500"
        >{@value || ""}</textarea>
      <% :checkbox -> %>
        <div class="flex items-center">
          <input
            type="checkbox"
            id={field_id(@attribute)}
            name={"field[#{@attribute.name}]"}
            checked={@value == true}
            disabled={@disabled}
            class="h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-600 disabled:opacity-50"
          />
        </div>
      <% :select -> %>
        <select
          id={field_id(@attribute)}
          name={"field[#{@attribute.name}]"}
          disabled={@disabled}
          class="block w-full rounded-md border-0 py-1.5 pl-3 pr-10 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-indigo-600 sm:text-sm sm:leading-6 disabled:bg-gray-50 disabled:text-gray-500"
        >
          <option value="">Select...</option>
          <%= for option <- get_select_options(@attribute) do %>
            <option value={option.value} selected={@value == option.value}>
              {option.label}
            </option>
          <% end %>
        </select>
      <% :date_input -> %>
        <input
          type="date"
          id={field_id(@attribute)}
          name={"field[#{@attribute.name}]"}
          value={format_date_value(@value)}
          disabled={@disabled}
          class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6 disabled:bg-gray-50 disabled:text-gray-500"
        />
      <% :time_input -> %>
        <input
          type="time"
          id={field_id(@attribute)}
          name={"field[#{@attribute.name}]"}
          value={format_time_value(@value)}
          disabled={@disabled}
          class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6 disabled:bg-gray-50 disabled:text-gray-500"
        />
      <% :datetime_input -> %>
        <input
          type="datetime-local"
          id={field_id(@attribute)}
          name={"field[#{@attribute.name}]"}
          value={format_datetime_value(@value)}
          disabled={@disabled}
          class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6 disabled:bg-gray-50 disabled:text-gray-500"
        />
      <% :json_editor -> %>
        <textarea
          id={field_id(@attribute)}
          name={"field[#{@attribute.name}]"}
          rows="5"
          disabled={@disabled}
          placeholder="Enter valid JSON"
          class="block w-full rounded-md border-0 py-1.5 font-mono text-sm text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 disabled:bg-gray-50 disabled:text-gray-500"
        >{format_json_value(@value)}</textarea>
      <% _ -> %>
        <input
          type="text"
          id={field_id(@attribute)}
          name={"field[#{@attribute.name}]"}
          value={@value || ""}
          disabled={@disabled}
          class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6 disabled:bg-gray-50 disabled:text-gray-500"
        />
    <% end %>
    """
  end

  defp relationship_field(assigns) do
    ~H"""
    <div class="form-field">
      <label
        for={field_id_for_relationship(@relationship)}
        class="block text-sm font-medium leading-6 text-gray-900"
      >
        {@relationship.label}
        <%= if @relationship.required? do %>
          <span class="text-red-500">*</span>
        <% end %>
      </label>

      <div class="mt-2">
        <%= if @relationship.cardinality == :one do %>
          <select
            id={field_id_for_relationship(@relationship)}
            name={"field[#{@relationship.name}]"}
            disabled={@disabled}
            class="block w-full rounded-md border-0 py-1.5 pl-3 pr-10 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-indigo-600 sm:text-sm sm:leading-6 disabled:bg-gray-50 disabled:text-gray-500"
          >
            <option value="">Select...</option>
            <!-- Options would be populated from relationship data -->
          </select>
        <% else %>
          <select
            id={field_id_for_relationship(@relationship)}
            name={"field[#{@relationship.name}][]"}
            multiple
            disabled={@disabled}
            class="block w-full rounded-md border-0 py-1.5 pl-3 pr-10 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-indigo-600 sm:text-sm sm:leading-6 disabled:bg-gray-50 disabled:text-gray-500"
          >
            <!-- Options would be populated from relationship data -->
          </select>
        <% end %>
      </div>

      <%= if @error do %>
        <p class="mt-2 text-sm text-red-600" id={"#{field_id_for_relationship(@relationship)}-error"}>
          {@error}
        </p>
      <% end %>

      <%= if @relationship.description do %>
        <p class="mt-2 text-sm text-gray-500">
          {@relationship.description}
        </p>
      <% end %>
    </div>
    """
  end

  defp form_grid_class(:single_column), do: "space-y-6"
  defp form_grid_class(:two_column), do: "grid grid-cols-1 gap-x-6 gap-y-6 sm:grid-cols-2"

  defp form_grid_class(:grid),
    do: "grid grid-cols-1 gap-x-6 gap-y-6 sm:grid-cols-2 lg:grid-cols-3"

  defp field_id(attribute), do: "field_#{attribute.name}"
  defp field_id_for_relationship(relationship), do: "field_#{relationship.name}"

  defp get_field_error(errors, field_name) do
    case Map.get(errors, field_name) do
      nil -> nil
      error when is_binary(error) -> error
      errors when is_list(errors) -> Enum.join(errors, ", ")
      _ -> "Invalid value"
    end
  end

  defp get_select_options(_attribute) do
    # This would be populated from attribute constraints or a provided options list
    # For now, return empty list - in real usage, this would come from the computer
    []
  end

  defp format_date_value(%Date{} = date), do: Date.to_string(date)
  defp format_date_value(nil), do: ""
  defp format_date_value(value) when is_binary(value), do: value
  defp format_date_value(_), do: ""

  defp format_time_value(%Time{} = time), do: Time.to_string(time)
  defp format_time_value(nil), do: ""
  defp format_time_value(value) when is_binary(value), do: value
  defp format_time_value(_), do: ""

  defp format_datetime_value(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%dT%H:%M")
  end

  defp format_datetime_value(%NaiveDateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%dT%H:%M")
  end

  defp format_datetime_value(nil), do: ""
  defp format_datetime_value(value) when is_binary(value), do: value
  defp format_datetime_value(_), do: ""

  defp format_json_value(nil), do: ""

  defp format_json_value(value) when is_map(value) or is_list(value) do
    Jason.encode!(value, pretty: true)
  rescue
    _ -> inspect(value)
  end

  defp format_json_value(value) when is_binary(value), do: value
  defp format_json_value(value), do: inspect(value)

  defp submit_button_text(:create), do: "Create"
  defp submit_button_text(:update), do: "Update"
  defp submit_button_text(_), do: "Submit"

  defp success_message(:create), do: "Record created successfully!"
  defp success_message(:update), do: "Record updated successfully!"
  defp success_message(_), do: "Success!"
end
