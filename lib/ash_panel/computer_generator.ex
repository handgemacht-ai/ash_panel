defmodule AshPanel.ComputerGenerator do
  @moduledoc """
  Generates AshComputer definitions from ResourceSchemas.

  This module provides macros that auto-generate computers for list views,
  detail views, and forms based on introspected Ash resource metadata.

  ## Usage

      defmodule MyApp.UsersLive do
        use Phoenix.LiveView
        use AshComputer.LiveView

        use AshPanel.ComputerGenerator,
          resource: MyApp.Accounts.User,
          domain: MyApp.Accounts,
          views: [:list, :detail, :form]
      end

  This generates three computers:
  - `:list_view` - Pagination, filtering, sorting
  - `:detail_view` - Single record with relationships
  - `:form_view` - Create/update with validation

  ## Options

  - `resource` (required) - The Ash resource module
  - `domain` (required) - The Ash domain
  - `views` (optional) - List of views to generate (default: [:list])
  - `overrides` (optional) - ResourceSchema overrides
  - Other resource-specific options passed to introspection

  ## Generated Computers

  ### List View Computer (`:list_view`)

  Combines filtering, pagination, and sorting:

  **Inputs:**
  - `filters` - Filter specs (usually connected from filters computer)
  - `page` - Current page
  - `page_size` - Items per page
  - `sort` - Sort field and direction
  - `actor` - Current user for authorization

  **Vals:**
  - `query_result` - Paginated, filtered, sorted records
  - `total_count` - Total filtered count
  - `total_pages` - Total pages
  - `has_next_page` / `has_prev_page` - Navigation flags
  - `columns` - Column definitions for table

  **Events:**
  - `next_page`, `prev_page`, `set_page`
  - `set_page_size`
  - `set_sort`

  ### Detail View Computer (`:detail_view`)

  Loads a single record with relationships:

  **Inputs:**
  - `record_id` - ID of record to load
  - `actor` - Current user for authorization

  **Vals:**
  - `record` - The loaded record with relationships
  - `actions` - Available actions for this record

  ### Form View Computer (`:form_view`)

  Manages create/update forms:

  **Inputs:**
  - `record_id` - ID for update (nil for create)
  - `form_data` - Current form field values
  - `actor` - Current user for authorization

  **Vals:**
  - `record` - Existing record (for update)
  - `fields` - Form field definitions
  - `errors` - Validation errors

  **Events:**
  - `set_field` - Update a field value
  - `submit` - Submit the form
  - `reset` - Reset form to initial state

  ## Example

      # Full setup with all computers
      defmodule MyApp.UsersLive do
        use Phoenix.LiveView
        use AshComputer.LiveView

        use AshPanel.ComputerGenerator,
          resource: MyApp.Accounts.User,
          domain: MyApp.Accounts,
          views: [:list, :detail, :form],
          overrides: %{
            attributes: %{
              email: %{label: "Email Address"}
            }
          }

        @impl true
        def mount(_params, _session, socket) do
          # Computers are already defined by the macro
          {:ok, mount_computers(socket)}
        end

        @impl true
        def render(assigns) do
          ~H\"\"\"
          <!-- Computers provide all the data via assigns -->
          <.list_view
            rows={@list_view_query_result}
            columns={@list_view_columns}
            ...
          />
          \"\"\"
        end
      end
  """

  @doc """
  Main macro that generates computers based on configuration.
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

    {resource, _} = Code.eval_quoted(resource_ast, [], caller)
    {domain, _} = Code.eval_quoted(domain_ast, [], caller)
    {views, _} = Code.eval_quoted(views_ast, [], caller)
    {overrides, _} = Code.eval_quoted(overrides_ast, [], caller)
    {list_opts, _} = Code.eval_quoted(list_opts_ast, [], caller)
    {detail_opts, _} = Code.eval_quoted(detail_opts_ast, [], caller)
    {form_opts, _} = Code.eval_quoted(form_opts_ast, [], caller)

    base_opts = [resource: resource, domain: domain, overrides: overrides]
    list_opts = Keyword.merge(base_opts, list_opts)
    detail_opts = Keyword.merge(base_opts, detail_opts)
    form_opts = Keyword.merge(base_opts, form_opts)

    quote generated: true do
      # Import necessary modules
      require AshPanel.ComputerGenerator.ListComputer
      require AshPanel.ComputerGenerator.DetailComputer
      require AshPanel.ComputerGenerator.FormComputer

      # Store configuration for runtime use
      @ash_panel_resource unquote(resource)
      @ash_panel_domain unquote(domain)
      @ash_panel_views unquote(Macro.escape(views))
      @ash_panel_overrides unquote(Macro.escape(overrides))

      # Generate requested computers
      if :list in unquote(views) do
        use AshPanel.ComputerGenerator.ListComputer, unquote(Macro.escape(list_opts))
      end

      if :detail in unquote(views) do
        use AshPanel.ComputerGenerator.DetailComputer, unquote(Macro.escape(detail_opts))
      end

      if :form in unquote(views) do
        use AshPanel.ComputerGenerator.FormComputer, unquote(Macro.escape(form_opts))
      end

      # Provide helper to get ResourceSchema at runtime
      def __ash_panel_schema__ do
        AshPanel.Introspection.build_resource_schema(
          @ash_panel_resource,
          @ash_panel_domain,
          overrides: @ash_panel_overrides
        )
      end
    end
  end
end
