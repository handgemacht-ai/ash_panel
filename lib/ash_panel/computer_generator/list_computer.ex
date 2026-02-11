defmodule AshPanel.ComputerGenerator.ListComputer do
  @moduledoc """
  Generates a list view computer from a ResourceSchema.

  Creates a computer that handles pagination, filtering, sorting, and querying
  for a resource. Automatically discovers columns, preloads, and filter fields.

  ## Generated Computer: `:list_view`

  ### Inputs
  - `filters` - List of filter specs (connect from filters computer)
  - `page` - Current page number (1-indexed)
  - `page_size` - Number of items per page
  - `sort_field` - Field to sort by
  - `sort_order` - Sort order (:asc or :desc)
  - `actor` - Current user for authorization

  ### Vals
  - `query_result` - Paginated, filtered, sorted records
  - `total_count` - Total number of items (filtered)
  - `total_pages` - Total number of pages
  - `has_next_page` - Whether there is a next page
  - `has_prev_page` - Whether there is a previous page
  - `columns` - Column definitions for table display
  - `resource_schema` - The ResourceSchema for this resource

  ### Events
  - `next_page` - Navigate to next page
  - `prev_page` - Navigate to previous page
  - `set_page` - Jump to specific page
  - `set_page_size` - Change items per page
  - `set_sort` - Change sort field/order
  """

  defmacro __using__(opts) do
    caller = __CALLER__

    eval = fn ast ->
      {value, _} = Code.eval_quoted(ast, [], caller)
      value
    end

    resource = opts |> Keyword.fetch!(:resource) |> eval.()
    domain = opts |> Keyword.fetch!(:domain) |> eval.()
    overrides = opts |> Keyword.get(:overrides, quote(do: %{})) |> eval.()
    default_sort_opt = opts |> Keyword.get(:default_sort) |> maybe_eval(eval)
    default_page_size = opts |> Keyword.get(:default_page_size, quote(do: 25)) |> eval.()

    page_size_options =
      opts |> Keyword.get(:page_size_options, quote(do: [10, 25, 50])) |> eval.()

    preload_override = opts |> Keyword.get(:preload) |> maybe_eval(eval)
    authorize? = opts |> Keyword.get(:authorize?, quote(do: true)) |> eval.()

    filter_fun =
      opts
      |> Keyword.get(:filter_fun, quote(do: &AshPanel.QueryFilters.apply_filters/2))
      |> eval.()

    base_query_fun = opts |> Keyword.get(:base_query_fun) |> maybe_eval(eval)

    schema =
      AshPanel.Introspection.build_resource_schema(
        resource,
        domain,
        overrides: overrides
      )

    default_sort =
      cond do
        is_list(default_sort_opt) && default_sort_opt != [] ->
          Enum.map(default_sort_opt, fn
            {field, direction} -> {field, direction}
            {field, direction, _} -> {field, direction}
            keyword when is_list(keyword) -> List.first(keyword)
            {field, direction} -> {field, direction}
            other when is_atom(other) -> {other, :asc}
          end)

        true ->
          schema.default_sort
      end

    default_sort_keyword = Keyword.new(default_sort)
    {default_sort_field, default_sort_order} = List.first(default_sort_keyword) || {:id, :asc}

    preloads =
      case preload_override do
        nil ->
          schema.relationships
          |> Enum.filter(& &1.show_in_table?)
          |> Enum.map(& &1.name)

        value ->
          value
      end

    sortable_fields =
      schema.attributes
      |> Enum.filter(& &1.sortable?)
      |> Enum.map(& &1.name)

    quote generated: true do
      @list_view_schema unquote(Macro.escape(schema))
      @list_view_preloads unquote(Macro.escape(preloads))
      @list_view_default_sort unquote(Macro.escape(default_sort_keyword))
      @list_view_default_sort_field unquote(default_sort_field)
      @list_view_default_sort_order unquote(default_sort_order)
      @list_view_default_page_size unquote(default_page_size)
      @list_view_page_size_options unquote(Macro.escape(page_size_options))
      @list_view_authorize? unquote(authorize?)
      @list_view_filter_fun unquote(Macro.escape(filter_fun))
      @list_view_base_query_fun unquote(Macro.escape(base_query_fun))
      @list_view_sortable_fields unquote(Macro.escape(sortable_fields))

      computer :list_view do
        input :filters do
          initial([])
          description("Active filters list (typically connected from filters computer)")
        end

        input :page do
          initial(1)
          description("Current page number (1-indexed)")
        end

        input :page_size do
          initial(@list_view_default_page_size)
          description("Number of items per page")
        end

        input :sort_field do
          initial(@list_view_default_sort_field)
          description("Field to sort by")
        end

        input :sort_order do
          initial(@list_view_default_sort_order)
          description("Sort order (:asc or :desc)")
        end

        input :actor do
          initial(nil)
          description("Current user for authorization")
        end

        input :refresh_trigger do
          initial(0)
          description("Increment to trigger re-computation")
        end

        val :query_result do
          description("Paginated, filtered, and sorted query result")

          compute(fn %{
                       filters: filters,
                       page: page,
                       page_size: page_size,
                       sort_field: sort_field,
                       sort_order: sort_order,
                       actor: actor,
                       refresh_trigger: _trigger
                     } ->
            offset =
              case page do
                p when p <= 1 -> 0
                p -> (p - 1) * page_size
              end

            filter_fun = @list_view_filter_fun

            base_query =
              case @list_view_base_query_fun do
                nil ->
                  unquote(resource)

                fun when is_function(fun, 0) ->
                  fun.()

                fun when is_function(fun, 1) ->
                  fun.(actor)

                {mod, fun} ->
                  apply(mod, fun, [actor])

                {mod, fun, extra} when is_list(extra) ->
                  apply(mod, fun, [actor | extra])

                other ->
                  raise ArgumentError,
                        "Unsupported base_query_fun: #{inspect(other)}. Expected nil, an arity 0/1 function, or {mod, fun, extra_args} tuple."
              end

            base_query
            |> filter_fun.(filters)
            |> Ash.Query.load(@list_view_preloads)
            |> Ash.Query.sort([{sort_field, sort_order}])
            |> Ash.Query.limit(page_size)
            |> Ash.Query.offset(offset)
            |> Ash.read!(
              domain: unquote(domain),
              actor: actor,
              authorize?: @list_view_authorize?
            )
          end)
        end

        val :total_count do
          description("Total number of items (filtered)")

          compute(fn %{filters: filters, actor: actor, refresh_trigger: _trigger} ->
            filter_fun = @list_view_filter_fun

            base_query =
              case @list_view_base_query_fun do
                nil ->
                  unquote(resource)

                fun when is_function(fun, 0) ->
                  fun.()

                fun when is_function(fun, 1) ->
                  fun.(actor)

                {mod, fun} ->
                  apply(mod, fun, [actor])

                {mod, fun, extra} when is_list(extra) ->
                  apply(mod, fun, [actor | extra])

                other ->
                  raise ArgumentError,
                        "Unsupported base_query_fun: #{inspect(other)}. Expected nil, an arity 0/1 function, or {mod, fun, extra_args} tuple."
              end

            base_query
            |> filter_fun.(filters)
            |> Ash.count!(
              domain: unquote(domain),
              actor: actor,
              authorize?: @list_view_authorize?
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

        val :loading do
          description("Whether the list is currently loading")

          compute(fn _ -> false end)
        end

        val :columns do
          description("Column definitions for table display")

          compute(fn _values ->
            AshPanel.Introspection.infer_columns(@list_view_schema)
          end)
        end

        val :resource_schema do
          description("The ResourceSchema for this resource")

          compute(fn _values ->
            @list_view_schema
          end)
        end

        val :page_size_options do
          description("Available page size options")

          compute(fn _values -> @list_view_page_size_options end)
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
          handle(fn _values, %{"page" => page_str} ->
            case Integer.parse(page_str) do
              {page, _} when page > 0 -> %{page: page}
              _ -> %{}
            end
          end)
        end

        event :set_page_size do
          handle(fn _values, %{"page_size" => size_str} ->
            case Integer.parse(size_str) do
              {size, _} when size > 0 -> %{page: 1, page_size: size}
              _ -> %{}
            end
          end)
        end

        event :set_sort do
          handle(fn %{sort_field: current_field, sort_order: current_order},
                    %{"field" => field_str} ->
            new_state =
              try do
                field = String.to_existing_atom(field_str)

                if field in @list_view_sortable_fields do
                  new_order =
                    if field == current_field do
                      if current_order == :asc, do: :desc, else: :asc
                    else
                      :asc
                    end

                  %{sort_field: field, sort_order: new_order}
                else
                  %{}
                end
              rescue
                ArgumentError ->
                  %{}
              end

            new_state
          end)
        end

        event :refresh do
          handle(fn %{refresh_trigger: trigger}, _payload ->
            %{refresh_trigger: trigger + 1}
          end)
        end
      end
    end
  end

  defp maybe_eval(nil, _eval), do: nil
  defp maybe_eval(ast, eval), do: eval.(ast)
end
