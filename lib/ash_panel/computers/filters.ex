defmodule AshPanel.Computers.Filters do
  @moduledoc """
  Reusable filters computer for LiveViews.

  Manages filter state and converts filter values to Ash-compatible filter specs.
  Can be used with resource-based auto-generation or pre-computed filter definitions.

  ## Usage

  ### Resource-based (recommended)

      use AshPanel.Computers.Filters,
        resource: MyApp.Accounts.User,
        fields: [:email, :role],
        overrides: %{email: %{label: "Email Address"}},
        additional_filters: [
          %AshPanel.Schema.FilterDefinition{
            field: :custom_field,
            operator: :gte,
            type: :number,
            label: "Custom Field",
            placeholder: "0"
          }
        ]

  ### Pre-computed definitions

      use AshPanel.Computers.Filters,
        filter_definitions: [
          %AshPanel.Schema.FilterDefinition{...},
          %AshPanel.Schema.FilterDefinition{...}
        ]

  ## Generated Computer

  This macro generates a computer named `:filters` with:

  ### Inputs
  - `values` - Map of filter field names to their values

  ### Vals
  - `active_filters` - List of active filter specs ready for Ash queries
  - `filter_count` - Number of active filters (counts unique fields)

  ### Events
  - `set_filter` - Update a filter value (payload: %{"field" => field, "value" => value})
  - `clear_all` - Clear all filter values

  ## Example

      defmodule MyApp.UsersLive do
        use Phoenix.LiveView
        use AshComputer.LiveView

        use AshPanel.Computers.Filters,
          resource: MyApp.Accounts.User,
          fields: [:email, :role]

        computer :list_view do
          input :filters do
            initial []
          end

          val :query_result do
            compute fn %{filters: filters} ->
              User
              |> AshPanel.QueryFilters.apply_filters(filters)
              |> Ash.read!()
            end
          end
        end

        @impl true
        def mount(_params, _session, socket) do
          executor =
            AshComputer.Executor.new()
            |> AshComputer.Executor.add_computer(__MODULE__, :filters)
            |> AshComputer.Executor.add_computer(__MODULE__, :list_view)
            |> AshComputer.Executor.connect(
              from: {:filters, :active_filters},
              to: {:list_view, :filters}
            )
            |> AshComputer.Executor.initialize()

          socket =
            socket
            |> assign(:__executor__, executor)
            |> AshComputer.LiveView.Helpers.sync_executor_to_assigns()

          {:ok, socket}
        end
      end
  """

  alias AshPanel.Schema.FilterDefinition

  defmacro __using__(opts) do
    filter_definitions_expr =
      if Keyword.has_key?(opts, :filter_definitions) do
        Keyword.fetch!(opts, :filter_definitions)
      else
        resource = Keyword.fetch!(opts, :resource)
        fields = Keyword.fetch!(opts, :fields)

        overrides =
          if Keyword.has_key?(opts, :overrides) do
            Keyword.fetch!(opts, :overrides)
          else
            quote do: %{}
          end

        additional =
          if Keyword.has_key?(opts, :additional_filters) do
            Keyword.fetch!(opts, :additional_filters)
          else
            quote do: []
          end

        quote do
          AshPanel.Introspection.FilterDefinitionBuilder.from_resource(
            unquote(resource),
            fields: unquote(fields),
            overrides: unquote(overrides)
          ) ++ unquote(__MODULE__).normalize_filter_definitions(unquote(additional))
        end
      end

    quote do
      @filter_definitions unquote(__MODULE__).normalize_filter_definitions(
                            unquote(filter_definitions_expr)
                          )

      computer :filters do
        input :values do
          initial(%{})
          description("Map of filter field names to their values")
        end

        val :active_filters do
          description("List of active filter specs for Ash queries")

          compute(fn %{values: values} ->
            AshPanel.Introspection.FilterDefinitionBuilder.to_ash_filters(
              @filter_definitions,
              values
            )
          end)
        end

        val :filter_count do
          description("Number of active filters (counts unique fields)")

          compute(fn %{active_filters: filters} ->
            filters
            |> Enum.map(& &1.field)
            |> Enum.uniq()
            |> length()
          end)
        end

        val :definitions do
          description("List of available filter definitions")

          compute(fn _ ->
            @filter_definitions
          end)
        end

        event :set_filter do
          handle(fn %{values: values}, %{"field" => field, "value" => raw_value} ->
            field_atom = String.to_existing_atom(field)
            filter_def = Enum.find(@filter_definitions, &(&1.field == field_atom))
            value = parse_filter_value(raw_value, filter_def)

            new_values =
              if value == nil do
                Map.delete(values, field_atom)
              else
                Map.put(values, field_atom, value)
              end

            %{values: new_values}
          end)
        end

        event :clear_all do
          handle(fn _values, _payload ->
            %{values: %{}}
          end)
        end
      end

      defp parse_filter_value("", _filter_def), do: nil

      defp parse_filter_value(raw_value, %{type: :boolean}) do
        case raw_value do
          "true" -> true
          "false" -> false
          true -> true
          false -> false
          _ -> nil
        end
      end

      defp parse_filter_value(raw_value, %{type: :number}) do
        case Integer.parse(raw_value) do
          {int, _} -> int
          :error -> nil
        end
      end

      defp parse_filter_value(raw_value, %{type: :select}), do: String.to_existing_atom(raw_value)

      defp parse_filter_value(raw_value, _filter_def), do: raw_value
    end
  end

  @doc """
  Normalizes a list of filter definitions into `AshPanel.Schema.FilterDefinition` structs.
  """
  def normalize_filter_definitions(definitions) when is_list(definitions) do
    Enum.map(definitions, &normalize_filter_definition/1)
  end

  def normalize_filter_definitions(nil), do: []

  defp normalize_filter_definition(%FilterDefinition{} = definition), do: definition

  defp normalize_filter_definition(%{} = definition) do
    struct(FilterDefinition, %{
      field: Map.fetch!(definition, :field),
      operator: Map.get(definition, :operator, :equals),
      type: Map.get(definition, :type, :search),
      options: Map.get(definition, :options),
      label: Map.get(definition, :label),
      placeholder: Map.get(definition, :placeholder)
    })
  end

  defp normalize_filter_definition(other),
    do: raise(ArgumentError, "Unsupported filter definition: #{inspect(other)}")
end
