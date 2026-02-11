defmodule AshPanel.ComputerGenerator.DetailComputer do
  @moduledoc """
  Generates a detail view computer from a ResourceSchema.

  Creates a computer that loads a single record with all its relationships
  and provides action metadata.

  ## Generated Computer: `:detail_view`

  ### Inputs
  - `record_id` - ID of the record to load (nil for no selection)
  - `show_modal` - Whether to show detail in a modal
  - `actor` - Current user for authorization

  ### Vals
  - `record` - The loaded record with relationships
  - `loading?` - Whether currently loading
  - `not_found?` - Whether record was not found
  - `attributes` - Attribute schemas to display
  - `relationships` - Relationship schemas to display
  - `actions` - Available actions for this record
  - `resource_schema` - The ResourceSchema for this resource

  ### Events
  - `select_record` - Load a record by ID
  - `close` - Clear selection and close modal
  - `refresh` - Reload current record
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
    preload_override = opts |> Keyword.get(:preload) |> maybe_eval(eval)
    authorize? = opts |> Keyword.get(:authorize?, quote(do: true)) |> eval.()

    schema =
      AshPanel.Introspection.build_resource_schema(
        resource,
        domain,
        overrides: overrides
      )

    preloads =
      case preload_override do
        nil ->
          schema.relationships
          |> Enum.filter(& &1.show_in_detail?)
          |> Enum.map(& &1.name)

        value ->
          value
      end

    quote do
      @detail_view_schema unquote(Macro.escape(schema))
      @detail_view_preloads unquote(Macro.escape(preloads))
      @detail_view_authorize? unquote(authorize?)

      computer :detail_view do
        input :record_id do
          initial(nil)
          description("ID of the record to load (nil for no selection)")
        end

        input :show_modal do
          initial(false)
          description("Whether to show detail in a modal")
        end

        input :actor do
          initial(nil)
          description("Current user for authorization")
        end

        input :refresh_trigger do
          initial(0)
          description("Increment to trigger refresh of current record")
        end

        val :record do
          description("The loaded record with relationships")

          compute(fn %{record_id: record_id, actor: actor, refresh_trigger: _trigger} ->
            case record_id do
              nil ->
                nil

              id ->
                try do
                  Ash.get!(
                    unquote(resource),
                    id,
                    domain: unquote(domain),
                    actor: actor,
                    authorize?: @detail_view_authorize?,
                    load: @detail_view_preloads
                  )
                rescue
                  Ash.Error.Query.NotFound ->
                    :not_found

                  error ->
                    require Logger

                    Logger.error("""
                    AshPanel Detail View: Failed to load record
                    Resource: #{inspect(unquote(resource))}
                    Record ID: #{inspect(id)}
                    Error: #{inspect(error)}
                    Stacktrace: #{Exception.format_stacktrace(__STACKTRACE__)}
                    """)

                    :error
                end
            end
          end)
        end

        val :loading? do
          description("Whether currently loading")

          compute(fn %{record_id: record_id, record: record} ->
            !is_nil(record_id) && is_nil(record)
          end)
        end

        val :not_found? do
          description("Whether record was not found")

          compute(fn %{record: record} ->
            record == :not_found
          end)
        end

        val :error? do
          description("Whether there was an error loading")

          compute(fn %{record: record} ->
            record == :error
          end)
        end

        val :attributes do
          description("Attribute schemas to display in detail view")

          compute(fn _values ->
            @detail_view_schema.attributes
            |> Enum.filter(& &1.show_in_detail?)
          end)
        end

        val :relationships do
          description("Relationship schemas to display in detail view")

          compute(fn _values ->
            @detail_view_schema.relationships
            |> Enum.filter(& &1.show_in_detail?)
          end)
        end

        val :actions do
          description("Available actions for this record")

          compute(fn %{record: record} ->
            case record do
              nil ->
                # Show only create actions when no record selected
                @detail_view_schema.actions
                |> Enum.filter(&(&1.type == :create))

              :not_found ->
                []

              :error ->
                []

              _record ->
                # Show update, destroy, and custom actions when record is loaded
                @detail_view_schema.actions
                |> Enum.filter(&(&1.type in [:update, :destroy, :action]))
            end
          end)
        end

        val :resource_schema do
          description("The ResourceSchema for this resource")

          compute(fn _values ->
            @detail_view_schema
          end)
        end

        event :select_record do
          handle(fn _values, %{"id" => id} ->
            %{record_id: id, show_modal: true}
          end)
        end

        event :load do
          handle(fn _values, %{"id" => id} ->
            %{record_id: id, show_modal: true}
          end)
        end

        event :close do
          handle(fn _values, _payload ->
            %{record_id: nil, show_modal: false}
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
