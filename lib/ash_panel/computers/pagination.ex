defmodule AshPanel.Computers.Pagination do
  @moduledoc """
  Reusable pagination computer for LiveViews.

  Generates a complete pagination computer with filtering, sorting, and pagination support.
  This computer handles querying Ash resources with filters, sorting, and pagination.

  ## Usage

      use AshPanel.Computers.Pagination,
        name: :users_table,
        resource: MyApp.Accounts.User,
        domain: MyApp.Accounts,
        preload: [:profile, posts: [:comments]],
        sort: [inserted_at: :desc]

  ## Generated Computer

  Creates a computer with the specified `name` containing:

  ### Inputs
  - `filters` - List of filter specs (typically connected from filters computer)
  - `page` - Current page number (1-indexed)
  - `page_size` - Number of items per page
  - `actor` - Current user for authorization

  ### Vals
  - `query_result` - Paginated and filtered query result
  - `total_count` - Total number of items (filtered)
  - `total_pages` - Total number of pages
  - `has_next_page` - Whether there is a next page
  - `has_prev_page` - Whether there is a previous page

  ### Events
  - `next_page` - Navigate to next page
  - `prev_page` - Navigate to previous page
  - `set_page` - Jump to specific page (payload: %{page: page_number})
  - `set_page_size` - Change page size (payload: %{page_size: size})

  ## Options

  - `name` (required) - Name for the computer (e.g., `:users_table`)
  - `resource` (required) - Ash resource module to query
  - `domain` (required) - Ash domain for the resource
  - `preload` (optional) - List of relationships to preload, defaults to `[]`
  - `sort` (optional) - Sort order keyword list, defaults to `[inserted_at: :desc]`

  ## Example

      defmodule MyApp.UsersLive do
        use Phoenix.LiveView
        use AshComputer.LiveView

        use AshPanel.Computers.Filters,
          resource: MyApp.Accounts.User,
          fields: [:email, :role]

        use AshPanel.Computers.Pagination,
          name: :users_table,
          resource: MyApp.Accounts.User,
          domain: MyApp.Accounts,
          preload: [:profile],
          sort: [email: :asc]

        @impl true
        def mount(_params, _session, socket) do
          executor =
            AshComputer.Executor.new()
            |> AshComputer.Executor.add_computer(__MODULE__, :filters)
            |> AshComputer.Executor.add_computer(__MODULE__, :users_table)
            |> AshComputer.Executor.connect(
              from: {:filters, :active_filters},
              to: {:users_table, :filters}
            )
            |> AshComputer.Executor.initialize()
            |> then(fn exec ->
              exec
              |> AshComputer.Executor.start_frame()
              |> AshComputer.Executor.set_input(:users_table, :actor, socket.assigns.current_user)
              |> AshComputer.Executor.commit_frame()
            end)

          socket =
            socket
            |> assign(:__executor__, executor)
            |> AshComputer.LiveView.Helpers.sync_executor_to_assigns()

          {:ok, socket}
        end
      end
  """

  defmacro __using__(opts) do
    name = Keyword.fetch!(opts, :name)
    resource = Keyword.fetch!(opts, :resource)
    domain = Keyword.fetch!(opts, :domain)
    preload = Keyword.get(opts, :preload, [])
    sort = Keyword.get(opts, :sort, inserted_at: :desc)

    quote do
      computer unquote(name) do
        input :filters do
          initial([])
          description("Active filters list (typically connected from filters computer)")
        end

        input :page do
          initial(1)
          description("Current page number (1-indexed)")
        end

        input :page_size do
          initial(10)
          description("Number of items per page")
        end

        input :actor do
          initial(nil)
          description("Current user for authorization")
        end

        val :query_result do
          description("Paginated and filtered query result")

          compute(fn %{filters: filters, page: page, page_size: page_size, actor: actor} ->
            offset = (page - 1) * page_size

            unquote(resource)
            |> AshPanel.QueryFilters.apply_filters(filters)
            |> Ash.Query.load(unquote(preload))
            |> Ash.Query.sort(unquote(sort))
            |> Ash.Query.limit(page_size)
            |> Ash.Query.offset(offset)
            |> Ash.read!(domain: unquote(domain), actor: actor, authorize?: false)
          end)
        end

        val :total_count do
          description("Total number of items (filtered)")

          compute(fn %{filters: filters, actor: actor} ->
            unquote(resource)
            |> AshPanel.QueryFilters.apply_filters(filters)
            |> Ash.count!(
              domain: unquote(domain),
              actor: actor,
              authorize?: false
            )
          end)
        end

        val :total_pages do
          description("Total number of pages")

          compute(fn %{total_count: total_count, page_size: page_size} ->
            case total_count do
              0 -> 1
              count -> ceil(count / page_size)
            end
          end)
        end

        val :has_next_page do
          description("Whether there is a next page")

          compute(fn %{page: page, total_pages: total_pages} ->
            page < total_pages
          end)
        end

        val :has_prev_page do
          description("Whether there is a previous page")

          compute(fn %{page: page} ->
            page > 1
          end)
        end

        event :next_page do
          handle(fn %{page: page, has_next_page: has_next_page}, _payload ->
            if has_next_page do
              %{page: page + 1}
            else
              %{}
            end
          end)
        end

        event :prev_page do
          handle(fn %{page: page, has_prev_page: has_prev_page}, _payload ->
            if has_prev_page do
              %{page: page - 1}
            else
              %{}
            end
          end)
        end

        event :set_page do
          handle(fn _values, %{page: new_page} ->
            %{page: new_page}
          end)
        end

        event :set_page_size do
          handle(fn _values, %{page_size: new_page_size} ->
            %{page: 1, page_size: new_page_size}
          end)
        end
      end
    end
  end
end
