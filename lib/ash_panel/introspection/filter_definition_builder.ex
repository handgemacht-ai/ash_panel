defmodule AshPanel.Introspection.FilterDefinitionBuilder do
  @moduledoc """
  Builds filter definitions from Ash resource attributes.

  Automatically infers the appropriate filter type, operator, and options
  based on the attribute's type and constraints.
  """

  alias Ash.Resource.Info
  alias Ash.Type.CiString
  alias Ash.Type.UtcDatetimeUsec
  alias AshPanel.Schema.FilterDefinition

  @doc """
  Generates filter definitions from an Ash resource.

  ## Options

  - `fields` - List of field names to create filters for (required)
  - `overrides` - Map of field overrides (optional)

  ## Examples

      iex> FilterDefinitionBuilder.from_resource(User, fields: [:email, :role])
      [
        %FilterDefinition{field: :email, type: :search, operator: :contains, ...},
        %FilterDefinition{field: :role, type: :select, operator: :equals, ...}
      ]

      iex> FilterDefinitionBuilder.from_resource(User,
      ...>   fields: [:email],
      ...>   overrides: %{email: %{label: "Email Address"}}
      ...> )
      [%FilterDefinition{field: :email, label: "Email Address", ...}]
  """
  def from_resource(resource, opts \\ []) do
    fields = Keyword.fetch!(opts, :fields)
    overrides = Keyword.get(opts, :overrides, %{})

    fields
    |> Enum.map(fn field ->
      attribute = Info.attribute(resource, field)
      build_filter_definition(attribute, Map.get(overrides, field, %{}))
    end)
  end

  @doc """
  Converts filter definitions and values to Ash-compatible filter specs.

  ## Examples

      iex> definitions = [
      ...>   %FilterDefinition{field: :email, operator: :contains},
      ...>   %FilterDefinition{field: :role, operator: :equals}
      ...> ]
      iex> values = %{email: "john", role: :admin}
      iex> FilterDefinitionBuilder.to_ash_filters(definitions, values)
      [
        %{field: :email, operator: :contains, value: "john"},
        %{field: :role, operator: :equals, value: :admin}
      ]
  """
  def to_ash_filters(definitions, values) do
    definitions
    |> Enum.filter(fn definition ->
      value = Map.get(values, definition.field)
      value != nil and value != "" and value != []
    end)
    |> Enum.flat_map(fn definition ->
      value = Map.get(values, definition.field)
      expand_filter(definition.field, definition.operator, value)
    end)
  end

  # Private functions

  defp build_filter_definition(attribute, overrides) do
    base_definition = infer_from_attribute_type(attribute)

    %FilterDefinition{
      field: attribute.name,
      operator: overrides[:operator] || base_definition.operator,
      type: overrides[:type] || base_definition.type,
      options: overrides[:options] || base_definition.options,
      label: overrides[:label] || format_label(attribute.name),
      placeholder: overrides[:placeholder] || base_definition.placeholder
    }
  end

  defp infer_from_attribute_type(attribute) do
    type_module = attribute.type

    cond do
      string_type?(type_module) ->
        %{operator: :contains, type: :search, options: nil, placeholder: "Search..."}

      atom_type?(type_module) ->
        infer_atom_filter(attribute)

      datetime_type?(type_module) ->
        %{operator: :gte, type: :date_range, options: nil, placeholder: nil}

      boolean_type?(type_module) ->
        %{operator: :equals, type: :boolean, options: [true, false], placeholder: "All"}

      integer_type?(type_module) ->
        %{operator: :equals, type: :number, options: nil, placeholder: "Enter number"}

      true ->
        %{operator: :equals, type: :search, options: nil, placeholder: "Enter value..."}
    end
  end

  defp string_type?(type_module) do
    type_module in [Ash.Type.String, CiString, :string, :ci_string]
  end

  defp atom_type?(type_module) do
    type_module in [Ash.Type.Atom, :atom]
  end

  defp datetime_type?(type_module) do
    type_module in [UtcDatetimeUsec, Ash.Type.Date, :utc_datetime_usec, :date]
  end

  defp boolean_type?(type_module) do
    type_module in [Ash.Type.Boolean, :boolean]
  end

  defp integer_type?(type_module) do
    type_module in [Ash.Type.Integer, :integer]
  end

  defp infer_atom_filter(attribute) do
    case get_atom_constraints(attribute) do
      nil ->
        %{operator: :equals, type: :search, options: nil, placeholder: "Enter value..."}

      options ->
        %{operator: :equals, type: :select, options: options, placeholder: "All"}
    end
  end

  defp get_atom_constraints(attribute) do
    case attribute.constraints[:one_of] do
      nil -> nil
      options when is_list(options) -> options
    end
  end

  defp expand_filter(field, :range, operator_value_tuples) when is_list(operator_value_tuples) do
    Enum.map(operator_value_tuples, fn {operator, value} ->
      %{field: field, operator: operator, value: value}
    end)
  end

  defp expand_filter(field, operator, value) do
    [%{field: field, operator: operator, value: value}]
  end

  defp format_label(field) do
    field
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end
end
