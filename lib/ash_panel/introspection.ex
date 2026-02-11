defmodule AshPanel.Introspection do
  @moduledoc """
  Auto-discovers metadata from Ash resources.

  This module introspects Ash resources to build complete ResourceSchema structures
  that contain all information needed to generate admin interfaces.

  ## Usage

      # Build schema for a single resource
      schema = Introspection.build_resource_schema(MyApp.Accounts.User, MyApp.Accounts)

      # Discover all resources in a domain
      resources = Introspection.discover_resources(MyApp.Accounts)

      # Build schemas for all resources in a domain
      schemas = Introspection.build_schemas_for_domain(MyApp.Accounts)
  """

  alias Ash.Resource.Info

  alias AshPanel.Schema.{
    ResourceSchema,
    AttributeSchema,
    RelationshipSchema,
    ActionSchema,
    ColumnDefinition
  }

  @doc """
  Discovers all resources in an Ash domain.

  Returns a list of resource modules.

  ## Examples

      iex> Introspection.discover_resources(MyApp.Accounts)
      [MyApp.Accounts.User, MyApp.Accounts.Profile]
  """
  def discover_resources(domain) do
    domain
    |> Ash.Domain.Info.resources()
    |> Enum.reject(&is_private_resource?/1)
  end

  @doc """
  Builds a complete ResourceSchema from an Ash resource.

  ## Options

  - `overrides` - Map of field overrides (optional)
  - All options from ResourceSchema.new/3

  ## Examples

      iex> schema = Introspection.build_resource_schema(User, Accounts)
      %ResourceSchema{
        resource: User,
        domain: Accounts,
        attributes: [...],
        relationships: [...],
        actions: [...]
      }

      iex> schema = Introspection.build_resource_schema(User, Accounts,
      ...>   overrides: %{
      ...>     attributes: %{email: %{label: "Email Address"}}
      ...>   }
      ...> )
  """
  def build_resource_schema(resource, domain, opts \\ []) do
    overrides = Keyword.get(opts, :overrides, %{})
    attribute_overrides = Map.get(overrides, :attributes, %{})
    relationship_overrides = Map.get(overrides, :relationships, %{})
    action_overrides = Map.get(overrides, :actions, %{})

    # Build base schema
    schema = ResourceSchema.new(resource, domain, opts)

    # Introspect and add all metadata
    schema
    |> Map.put(:attributes, introspect_attributes(resource, attribute_overrides))
    |> Map.put(:relationships, introspect_relationships(resource, relationship_overrides))
    |> Map.put(:actions, introspect_actions(resource, action_overrides))
    |> Map.put(:calculations, introspect_calculations(resource))
    |> Map.put(:aggregates, introspect_aggregates(resource))
    |> Map.put(:identities, introspect_identities(resource))
    |> Map.put(:primary_key, get_primary_key(resource))
    |> Map.put(:display_field, guess_display_field(resource))
    |> Map.put(:searchable_fields, guess_searchable_fields(resource))
    |> Map.put(:table_name, get_table_name(resource))
  end

  @doc """
  Builds ResourceSchemas for all resources in a domain.

  ## Examples

      iex> schemas = Introspection.build_schemas_for_domain(MyApp.Accounts)
      [%ResourceSchema{...}, %ResourceSchema{...}]
  """
  def build_schemas_for_domain(domain, opts \\ []) do
    domain
    |> discover_resources()
    |> Enum.map(&build_resource_schema(&1, domain, opts))
  end

  @doc """
  Infers column definitions from a resource schema.

  Converts attributes and relationships into ColumnDefinition structs
  suitable for table rendering.

  ## Examples

      iex> schema = Introspection.build_resource_schema(User, Accounts)
      iex> columns = Introspection.infer_columns(schema)
      [%ColumnDefinition{field: :email, ...}, ...]
  """
  def infer_columns(%ResourceSchema{} = schema) do
    # Get table attributes
    table_attrs =
      schema.attributes
      |> Enum.filter(& &1.show_in_table?)
      |> Enum.map(&attribute_to_column/1)

    # Get table relationships (belongs_to only)
    table_rels =
      schema.relationships
      |> Enum.filter(& &1.show_in_table?)
      |> Enum.map(&relationship_to_column/1)

    table_attrs ++ table_rels
  end

  # Private functions

  defp introspect_attributes(resource, overrides) do
    resource
    |> Info.attributes()
    |> Enum.map(fn attr ->
      base_schema = AttributeSchema.new(attr)
      override = Map.get(overrides, attr.name, %{})
      AttributeSchema.override(base_schema, override)
    end)
  end

  defp introspect_relationships(resource, overrides) do
    resource
    |> Info.relationships()
    |> Enum.map(fn rel ->
      base_schema = RelationshipSchema.new(rel)
      override = Map.get(overrides, rel.name, %{})
      RelationshipSchema.override(base_schema, override)
    end)
  end

  defp introspect_actions(resource, overrides) do
    resource
    |> Info.actions()
    |> Enum.map(fn action ->
      base_schema = ActionSchema.new(action)
      override = Map.get(overrides, action.name, %{})
      ActionSchema.override(base_schema, override)
    end)
  end

  defp introspect_calculations(resource) do
    resource
    |> Info.calculations()
    |> Enum.map(fn calc ->
      %{
        name: calc.name,
        type: calc.type,
        description: calc.description,
        label: format_label(calc.name),
        public?: !Map.get(calc, :private?, false)
      }
    end)
  end

  defp introspect_aggregates(resource) do
    resource
    |> Info.aggregates()
    |> Enum.map(fn agg ->
      %{
        name: agg.name,
        kind: agg.kind,
        relationship_path: agg.relationship_path,
        description: agg.description,
        label: format_label(agg.name),
        public?: !Map.get(agg, :private?, false)
      }
    end)
  end

  defp introspect_identities(resource) do
    resource
    |> Info.identities()
    |> Enum.map(fn identity ->
      %{
        name: identity.name,
        keys: identity.keys,
        description: identity.description
      }
    end)
  end

  defp get_primary_key(resource) do
    case Info.primary_key(resource) do
      [single_key] -> single_key
      multiple_keys -> multiple_keys
    end
  end

  defp get_table_name(resource) do
    case Info.data_layer(resource) do
      Ash.DataLayer.Ets ->
        nil

      Ash.DataLayer.Mnesia ->
        nil

      _ ->
        # For SQL data layers, try to get the table name
        try do
          resource.__resource__(:data_layer)[:table]
        rescue
          _ -> nil
        end
    end
  end

  defp guess_display_field(resource) do
    # Preference order for display fields
    preferred_fields = [:name, :title, :display_name, :email, :username, :full_name, :label]

    attributes = Info.attributes(resource)

    Enum.find_value(preferred_fields, :id, fn field_name ->
      if Enum.any?(attributes, &(&1.name == field_name)) do
        field_name
      end
    end)
  end

  defp guess_searchable_fields(resource) do
    resource
    |> Info.attributes()
    |> Enum.filter(fn attr ->
      !attribute_private?(attr) && string_like_type?(attr.type)
    end)
    |> Enum.map(& &1.name)
  end

  defp string_like_type?(type) when is_atom(type) do
    type in [:string, :ci_string, :atom]
  end

  defp string_like_type?(type) do
    type in [Ash.Type.String, Ash.Type.CiString, Ash.Type.Atom]
  end

  defp is_private_resource?(_resource) do
    # Check if resource has a private? flag or is in a private namespace
    # Default to false, can be enhanced later
    false
  end

  defp attribute_to_column(%AttributeSchema{} = attr) do
    ColumnDefinition.new(attr.name, attr.type,
      label: attr.label,
      sortable: attr.sortable?,
      formatter: attr.formatter,
      align: infer_alignment(attr.type)
    )
  end

  defp relationship_to_column(%RelationshipSchema{} = rel) do
    ColumnDefinition.new(rel.name, :relationship,
      label: rel.label,
      sortable: false,
      formatter: &format_relationship/1
    )
  end

  defp infer_alignment(type) when is_atom(type) do
    if type in [:integer, :float, :decimal], do: :right, else: :left
  end

  defp infer_alignment(_type), do: :left

  defp format_relationship(value) when is_map(value) do
    # Try to display the relationship using common display fields
    Map.get(value, :name) || Map.get(value, :title) || Map.get(value, :email) || "Related"
  end

  defp format_relationship(_value), do: "-"

  defp format_label(name) do
    name
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp attribute_private?(attr) do
    Map.get(attr, :private?, !Map.get(attr, :public?, true))
  end
end
