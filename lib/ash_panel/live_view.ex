defmodule AshPanel.LiveView do
  @moduledoc """
  Main helper module for integrating AshPanel into Phoenix LiveViews.

  This module provides a simple macro-based approach to add resource management
  capabilities to your LiveViews with minimal boilerplate.

  ## Quick Start

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
          ~H\"\"\"
          <AshPanel.Layouts.MinimalLayout.render
            title="User Management"
            actions={[%{label: "New User", on_click: event(:form_view, :new), primary: true}]}
          >
            <AshPanel.Views.ListView.render
              rows={@list_view_rows}
              columns={@list_view_columns}
              current_page={@list_view_current_page}
              total_pages={@list_view_total_pages}
              on_page_change={event(:list_view, :set_page)}
              filter_definitions={@list_view_filter_definitions}
              filter_values={@list_view_filter_values}
              on_filter_change={event(:list_view, :set_filter)}
            />
          </AshPanel.Layouts.MinimalLayout.render>
          \"\"\"
        end
      end

  ## Customization

  You can customize the generated computers and views by providing options:

      use AshPanel.LiveView,
        resource: MyApp.Accounts.User,
        domain: MyApp.Accounts,
        views: [:list, :detail],
        list_view: [
          default_sort: [email: :asc],
          default_page_size: 50,
          filter_definitions: [
            %{field: :role, type: :select, options: ["admin", "user"]},
            %{field: :email, type: :search}
          ]
        ],
        detail_view: [
          preload: [:profile, :posts]
        ]

  ## Available Views

  - `:list` - Paginated table with filtering and sorting
  - `:detail` - Single record detail view with relationships
  - `:form` - Create/update form with validation

  ## Generated Assigns

  Each view generates its own set of assigns prefixed with the view name:

  ### List View
  - `@list_view_rows` - Current page of records
  - `@list_view_columns` - Column definitions
  - `@list_view_current_page` - Current page number
  - `@list_view_total_pages` - Total number of pages
  - `@list_view_filter_definitions` - Available filters
  - `@list_view_filter_values` - Current filter values
  - Plus many more...

  ### Detail View
  - `@detail_view_record` - The loaded record
  - `@detail_view_attributes` - Visible attributes
  - `@detail_view_relationships` - Visible relationships
  - `@detail_view_loading?` - Loading state
  - Plus more...

  ### Form View
  - `@form_view_mode` - :create or :update
  - `@form_view_form_data` - Current form values
  - `@form_view_errors` - Validation errors
  - `@form_view_submitting?` - Submission state
  - Plus more...

  ## Event Handling

  All events are automatically handled through the generated computers. You can
  use the `event/2` helper to generate event handlers:

      <button phx-click={event(:list_view, :next_page)}>Next</button>

  ## Custom Actions

  You can add custom actions by implementing handle_event in your LiveView:

      def handle_event("custom_action", params, socket) do
        # Your custom logic
        {:noreply, socket}
      end
  """

  defmacro __using__(opts) do
    caller = __CALLER__

    resource_ast = Keyword.fetch!(opts, :resource)
    domain_ast = Keyword.fetch!(opts, :domain)
    views_ast = Keyword.get(opts, :views, quote(do: [:list]))
    overrides_ast = Keyword.get(opts, :overrides, quote(do: %{}))
    list_opts_ast = Keyword.get(opts, :list, quote(do: []))
    detail_opts_ast = Keyword.get(opts, :detail, quote(do: []))
    form_opts_ast = Keyword.get(opts, :form, quote(do: []))
    filters_ast = Keyword.get(opts, :filters, quote(do: :auto))

    {resource, _} = Code.eval_quoted(resource_ast, [], caller)
    {domain, _} = Code.eval_quoted(domain_ast, [], caller)
    {views, _} = Code.eval_quoted(views_ast, [], caller)
    {overrides, _} = Code.eval_quoted(overrides_ast, [], caller)
    {list_opts, _} = Code.eval_quoted(list_opts_ast, [], caller)
    {detail_opts, _} = Code.eval_quoted(detail_opts_ast, [], caller)
    {form_opts, _} = Code.eval_quoted(form_opts_ast, [], caller)
    {filters_option, _} = Code.eval_quoted(filters_ast, [], caller)

    schema = AshPanel.Introspection.build_resource_schema(resource, domain, overrides: overrides)

    default_filter_fields =
      case schema.searchable_fields do
        [] -> Enum.map(schema.attributes, & &1.name)
        fields -> fields
      end

    {filters_enabled?, filters_opts} =
      case filters_option do
        false ->
          {false, nil}

        :auto ->
          if default_filter_fields == [] do
            {false, nil}
          else
            {true,
             [
               resource: resource,
               fields: default_filter_fields
             ]}
          end

        nil ->
          if default_filter_fields == [] do
            {false, nil}
          else
            {true,
             [
               resource: resource,
               fields: default_filter_fields
             ]}
          end

        opts when is_list(opts) ->
          merged =
            opts
            |> Keyword.put_new(:fields, default_filter_fields)
            |> Keyword.put(:resource, resource)

          {true, merged}

        _other ->
          raise ArgumentError,
                "Invalid :filters option for AshPanel.LiveView. Expected false, :auto, nil, or a keyword list."
      end

    view_computers =
      Enum.map(views, fn
        :list -> :list_view
        :detail -> :detail_view
        :form -> :form_view
        other -> raise ArgumentError, "Unsupported view #{inspect(other)}"
      end)

    quote generated: true do
      use AshComputer.LiveView
      import Phoenix.Component, only: [assign: 3, sigil_H: 2]
      alias AshComputer.Executor
      alias AshComputer.LiveView.Helpers, as: AshPanelHelpers

      # Generate the computers for all requested views
      use AshPanel.ComputerGenerator,
        resource: unquote(resource),
        domain: unquote(domain),
        views: unquote(Macro.escape(views)),
        overrides: unquote(Macro.escape(overrides)),
        list: unquote(Macro.escape(list_opts)),
        detail: unquote(Macro.escape(detail_opts)),
        form: unquote(Macro.escape(form_opts))

      if unquote(filters_enabled?) do
        use AshPanel.Computers.Filters, unquote(Macro.escape(filters_opts))
      end

      # Module attributes for easy access
      @ash_panel_resource unquote(resource)
      @ash_panel_domain unquote(domain)
      @ash_panel_views unquote(Macro.escape(views))
      @ash_panel_overrides unquote(Macro.escape(overrides))
      @ash_panel_schema unquote(Macro.escape(schema))
      @ash_panel_filter_enabled? unquote(filters_enabled?)
      @ash_panel_computers unquote(Macro.escape(view_computers))
      @ash_panel_list_opts unquote(Macro.escape(list_opts))
      @ash_panel_detail_opts unquote(Macro.escape(detail_opts))
      @ash_panel_form_opts unquote(Macro.escape(form_opts))

      # Helper function to set up AshPanel in mount
      def setup_ash_panel(socket, opts \\ []) do
        actor = Keyword.get(opts, :actor)
        configure_executor = Keyword.get(opts, :configure_executor, & &1)
        after_setup = Keyword.get(opts, :after_setup, fn executor, _actor -> executor end)

        executor =
          build_ash_panel_executor(
            actor: actor,
            configure_executor: configure_executor,
            after_setup: after_setup
          )

        socket =
          socket
          |> assign(:__executor__, executor)
          |> maybe_assign_filter_definitions()

        socket
        |> AshPanelHelpers.sync_executor_to_assigns()
      end

      # Helper to show detail view for a specific record
      def show_detail(socket, record_id) do
        if :detail in @ash_panel_views do
          socket
          |> send_event(:detail_view, :select_record, %{"id" => record_id})
        else
          socket
        end
      end

      # Helper to show create form
      def show_create_form(socket) do
        if :form in @ash_panel_views do
          socket
          |> send_event(:form_view, :new, %{})
        else
          socket
        end
      end

      # Helper to show edit form for a record
      def show_edit_form(socket, record_id) do
        if :form in @ash_panel_views do
          socket
          |> send_event(:form_view, :edit, %{"id" => record_id})
        else
          socket
        end
      end

      # Helper to refresh list view
      def refresh_list(socket) do
        if :list in @ash_panel_views do
          socket
          |> send_event(:list_view, :refresh, %{"trigger" => System.unique_integer([:positive])})
        else
          socket
        end
      end

      defp build_ash_panel_executor(opts) do
        actor = Keyword.get(opts, :actor)
        configure_executor = Keyword.get(opts, :configure_executor, & &1)
        after_setup = Keyword.get(opts, :after_setup, fn executor, _actor -> executor end)

        executor =
          Executor.new()
          |> maybe_add_filters()
          |> add_view_computers()
          |> maybe_connect_filters_to_list()
          |> configure_executor.()
          |> Executor.initialize()
          |> Executor.start_frame()
          |> maybe_set_actor(:list_view, actor)
          |> maybe_set_actor(:detail_view, actor)
          |> maybe_set_actor(:form_view, actor)

        executor = after_setup.(executor, actor)

        Executor.commit_frame(executor)
      end

      defp maybe_assign_filter_definitions(socket) do
        if @ash_panel_filter_enabled? do
          assign(socket, :filter_definitions, @filter_definitions)
        else
          socket
        end
      end

      defp maybe_add_filters(executor) do
        if @ash_panel_filter_enabled? do
          Executor.add_computer(executor, __MODULE__, :filters)
        else
          executor
        end
      end

      defp add_view_computers(executor) do
        Enum.reduce(@ash_panel_computers, executor, fn computer, acc ->
          Executor.add_computer(acc, __MODULE__, computer)
        end)
      end

      defp maybe_connect_filters_to_list(executor) do
        if @ash_panel_filter_enabled? and :list in @ash_panel_views do
          Executor.connect(
            executor,
            from: {:filters, :active_filters},
            to: {:list_view, :filters}
          )
        else
          executor
        end
      end

      defp maybe_set_actor(executor, computer, actor) do
        if Enum.member?(@ash_panel_computers, computer) do
          Executor.set_input(executor, computer, :actor, actor)
        else
          executor
        end
      end

      defp send_event(socket, computer_name, event_name, params) do
        executor = AshPanelHelpers.get_executor_from_assigns(socket)

        unless executor do
          raise ArgumentError,
                "No executor found in socket assigns. Did you call setup_ash_panel/1?"
        end

        # Get the computer definition
        computer_def = AshComputer.Info.computer(__MODULE__, computer_name)

        unless computer_def do
          raise ArgumentError,
                "Computer #{inspect(computer_name)} not found in module #{inspect(__MODULE__)}"
        end

        # Find the event
        event = Enum.find(computer_def.events, &(&1.name == event_name))

        unless event do
          available_events = Enum.map(computer_def.events, & &1.name)

          raise ArgumentError,
                "Event #{inspect(event_name)} not found in computer #{inspect(computer_name)}. " <>
                  "Available events: #{inspect(available_events)}"
        end

        # Get current values for the computer
        values = AshComputer.Executor.current_values(executor, computer_name)

        # Call the event handler
        changes =
          cond do
            is_function(event.handle, 1) ->
              event.handle.(values)

            is_function(event.handle, 2) ->
              event.handle.(values, params)

            true ->
              raise ArgumentError, "Event handler must be a function of arity 1 or 2"
          end

        unless is_map(changes) do
          raise ArgumentError, "Event handler must return a map of input changes"
        end

        # Apply the changes
        updated_executor =
          executor
          |> Executor.start_frame()
          |> then(fn exec ->
            Enum.reduce(changes, exec, fn {input_name, value}, acc ->
              Executor.set_input(acc, computer_name, input_name, value)
            end)
          end)
          |> Executor.commit_frame()

        # Update socket
        socket
        |> assign(:__executor__, updated_executor)
        |> AshPanelHelpers.sync_executor_to_assigns()
      end

      defoverridable setup_ash_panel: 1,
                     setup_ash_panel: 2,
                     show_detail: 2,
                     show_create_form: 1,
                     show_edit_form: 2,
                     refresh_list: 1,
                     maybe_assign_filter_definitions: 1,
                     maybe_add_filters: 1,
                     add_view_computers: 1,
                     maybe_connect_filters_to_list: 1,
                     maybe_set_actor: 3,
                     build_ash_panel_executor: 1
    end
  end

  @doc """
  Generates an event handler reference for use in templates.

  ## Examples

      event(:list_view, :next_page)
      event(:form_view, :submit)
      event(:detail_view, :load)
  """
  def event(computer_name, event_name) do
    "#{computer_name}_#{event_name}"
  end
end
