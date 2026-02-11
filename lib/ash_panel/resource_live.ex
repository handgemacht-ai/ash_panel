defmodule AshPanel.ResourceLive do
  @moduledoc """
  Base LiveView module for AshPanel resource management.

  This module can be used directly or as a starting point for customization.
  It handles all CRUD operations (index, show, new, edit) in a single LiveView.

  ## Usage

  ### Direct Usage

      defmodule MyAppWeb.Admin.UsersLive do
        use AshPanel.ResourceLive,
          resource: MyApp.Accounts.User,
          domain: MyApp.Accounts
      end

  ### With Customization

      defmodule MyAppWeb.Admin.UsersLive do
        use AshPanel.ResourceLive,
          resource: MyApp.Accounts.User,
          domain: MyApp.Accounts

        # Override mount to add custom logic
        def mount(params, session, socket) do
          socket = super(params, session, socket)
          # Add custom assigns
          {:ok, assign(socket, :custom_data, load_custom_data())}
        end

        # Override render for custom layout
        def render(assigns) do
          ~H\"\"\"
          <div class="custom-wrapper">
            <%= super(assigns) %>
          </div>
          \"\"\"
        end
      end

  ## LiveView Actions

  The live_action determines which view is shown:
  - `:index` - List view with table, filters, pagination
  - `:show` - Detail view for a single record
  - `:new` - Create form
  - `:edit` - Update form
  """

  defmacro __using__(opts) do
    resource = Keyword.fetch!(opts, :resource)
    domain = Keyword.fetch!(opts, :domain)
    layout_module = Keyword.get(opts, :layout, AshPanel.Layouts.MinimalLayout)
    title = Keyword.get(opts, :title)

    quote do
      use Phoenix.LiveView

      use AshPanel.LiveView,
        resource: unquote(resource),
        domain: unquote(domain),
        views: [:list, :detail, :form]

      @layout_module unquote(layout_module)
      @resource unquote(resource)
      @domain unquote(domain)
      @custom_title unquote(title)

      def mount(params, _session, socket) do
        socket =
          socket
          |> assign(:current_view, :index)
          |> assign(:selected_id, nil)
          |> setup_ash_panel(actor: get_actor(socket))

        socket = handle_mount_params(socket, params)

        {:ok, socket}
      end

      def handle_params(params, _url, socket) do
        socket = handle_route_params(socket, params, socket.assigns.live_action)
        {:noreply, socket}
      end

      def render(assigns) do
        ~H"""
        <@layout_module.render
          title={page_title(@live_action, @resource)}
          actions={page_actions(@live_action)}
        >
          <%= case @live_action do %>
            <% :index -> %>
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
                on_row_click={&JS.patch("/#{resource_path(@resource)}/#{&1["id"]}")}
                on_sort={event(:list_view, :set_sort)}
                on_filter_change={event(:list_view, :set_filter)}
                on_clear_filters={event(:list_view, :clear_all_filters)}
                on_next_page={event(:list_view, :next_page)}
                on_prev_page={event(:list_view, :prev_page)}
                on_page_size_change={event(:list_view, :set_page_size)}
              />

            <% :show -> %>
              <AshPanel.Views.DetailView.render
                record={@detail_view_record}
                attributes={@detail_view_attributes}
                relationships={@detail_view_relationships}
                actions={@detail_view_actions}
                loading?={@detail_view_loading}
                not_found?={@detail_view_not_found}
                error?={@detail_view_error}
                on_action={&handle_detail_action/1}
                on_back={&JS.patch("/#{resource_path(@resource)}")}
              />

            <% :new -> %>
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
                on_cancel={&JS.patch("/#{resource_path(@resource)}")}
              />

            <% :edit -> %>
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
                on_cancel={&JS.patch("/#{resource_path(@resource)}/#{@selected_id}")}
              />
          <% end %>
        </@layout_module.render>
        """
      end

      # Handle mount params (for initial page load)
      defp handle_mount_params(socket, %{"id" => id}) do
        socket
        |> assign(:selected_id, id)
        |> assign(:current_view, :show)
        |> show_detail(id)
      end

      defp handle_mount_params(socket, _params) do
        socket
      end

      # Handle route params (for live navigation)
      defp handle_route_params(socket, params, :index) do
        socket
        |> assign(:current_view, :index)
        |> assign(:selected_id, nil)
      end

      defp handle_route_params(socket, %{"id" => id}, :show) do
        socket
        |> assign(:current_view, :show)
        |> assign(:selected_id, id)
        |> show_detail(id)
      end

      defp handle_route_params(socket, _params, :new) do
        socket
        |> assign(:current_view, :new)
        |> assign(:selected_id, nil)
        |> show_create_form()
      end

      defp handle_route_params(socket, %{"id" => id}, :edit) do
        socket
        |> assign(:current_view, :edit)
        |> assign(:selected_id, id)
        |> show_edit_form(id)
      end

      defp handle_route_params(socket, _params, _action) do
        socket
      end

      # Page title based on action
      defp page_title(:index, resource) do
        @custom_title || humanize_resource_plural(resource)
      end

      defp page_title(:show, resource) do
        "View " <> humanize_resource(resource)
      end

      defp page_title(:new, resource) do
        "New " <> humanize_resource(resource)
      end

      defp page_title(:edit, resource) do
        "Edit " <> humanize_resource(resource)
      end

      # Page actions based on live_action
      defp page_actions(:index) do
        [
          %{
            label: "New " <> humanize_resource(@resource),
            on_click: JS.patch("/#{resource_path(@resource)}/new"),
            primary: true
          }
        ]
      end

      defp page_actions(:show) do
        [
          %{
            label: "Edit",
            on_click: "navigate_to_edit",
            primary: true
          },
          %{
            label: "Back to List",
            on_click: JS.patch("/#{resource_path(@resource)}"),
            primary: false
          }
        ]
      end

      defp page_actions(_), do: []

      # Handle detail actions
      def handle_event("detail_action", %{"action" => "edit"}, socket) do
        id = socket.assigns.selected_id
        {:noreply, push_patch(socket, to: "/#{resource_path(@resource)}/#{id}/edit")}
      end

      def handle_event("detail_action", %{"action" => "delete"}, socket) do
        # TODO: Implement delete action
        {:noreply, socket}
      end

      def handle_event("navigate_to_edit", _params, socket) do
        id = socket.assigns.selected_id
        {:noreply, push_patch(socket, to: "/#{resource_path(@resource)}/#{id}/edit")}
      end

      # Form submission success - redirect back to list or detail
      def handle_info({:form_submitted, result}, socket) do
        case socket.assigns.live_action do
          :new ->
            {:noreply, push_patch(socket, to: "/#{resource_path(@resource)}")}

          :edit ->
            id = socket.assigns.selected_id
            {:noreply, push_patch(socket, to: "/#{resource_path(@resource)}/#{id}")}
        end
      end

      # Get actor from socket (override this in your LiveView)
      defp get_actor(socket) do
        Map.get(socket.assigns, :current_user)
      end

      # Humanize resource name
      defp humanize_resource(resource) do
        resource
        |> Module.split()
        |> List.last()
        |> Phoenix.Naming.humanize()
      end

      defp humanize_resource_plural(resource) do
        resource
        |> Module.split()
        |> List.last()
        |> Phoenix.Naming.humanize()
        |> Inflex.pluralize()
      end

      # Get resource path
      defp resource_path(resource) do
        resource
        |> Module.split()
        |> List.last()
        |> Macro.underscore()
        |> Inflex.pluralize()
      end

      defp handle_detail_action(%{"action" => action}) do
        "detail_action"
      end

      # Allow overriding
      defoverridable mount: 3,
                     handle_params: 3,
                     render: 1,
                     get_actor: 1,
                     page_title: 2,
                     page_actions: 1
    end
  end
end
