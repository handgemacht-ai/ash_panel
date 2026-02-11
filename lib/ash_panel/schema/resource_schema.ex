defmodule AshPanel.Schema.ResourceSchema do
  @moduledoc """
  Complete metadata schema for an Ash resource.

  This structure holds all introspected information about an Ash resource,
  including attributes, relationships, actions, calculations, and aggregates.
  """

  alias AshPanel.Schema.{AttributeSchema, RelationshipSchema, ActionSchema}

  defstruct [
    :resource,
    :domain,
    :name,
    :plural_name,
    :primary_key,
    :attributes,
    :relationships,
    :actions,
    :calculations,
    :aggregates,
    :identities,
    :default_sort,
    :searchable_fields,
    :display_field,
    :description,
    :short_name,
    :table_name
  ]

  @type t :: %__MODULE__{
          resource: module(),
          domain: module(),
          name: String.t(),
          plural_name: String.t(),
          primary_key: atom() | list(atom()),
          attributes: list(AttributeSchema.t()),
          relationships: list(RelationshipSchema.t()),
          actions: list(ActionSchema.t()),
          calculations: list(map()),
          aggregates: list(map()),
          identities: list(map()),
          default_sort: keyword(),
          searchable_fields: list(atom()),
          display_field: atom(),
          description: String.t() | nil,
          short_name: String.t(),
          table_name: String.t() | nil
        }

  @doc """
  Creates a new ResourceSchema with default values.
  """
  def new(resource, domain, opts \\ []) do
    %__MODULE__{
      resource: resource,
      domain: domain,
      name: Keyword.get(opts, :name, default_name(resource)),
      plural_name: Keyword.get(opts, :plural_name, default_plural_name(resource)),
      primary_key: Keyword.get(opts, :primary_key, :id),
      attributes: Keyword.get(opts, :attributes, []),
      relationships: Keyword.get(opts, :relationships, []),
      actions: Keyword.get(opts, :actions, []),
      calculations: Keyword.get(opts, :calculations, []),
      aggregates: Keyword.get(opts, :aggregates, []),
      identities: Keyword.get(opts, :identities, []),
      default_sort: Keyword.get(opts, :default_sort, inserted_at: :desc),
      searchable_fields: Keyword.get(opts, :searchable_fields, []),
      display_field: Keyword.get(opts, :display_field, guess_display_field()),
      description: Keyword.get(opts, :description),
      short_name: Keyword.get(opts, :short_name, default_short_name(resource)),
      table_name: Keyword.get(opts, :table_name)
    }
  end

  @doc """
  Gets all public attributes (excludes private attributes).
  """
  def public_attributes(%__MODULE__{attributes: attrs}) do
    Enum.filter(attrs, & &1.public?)
  end

  @doc """
  Gets all filterable attributes.
  """
  def filterable_attributes(%__MODULE__{attributes: attrs}) do
    Enum.filter(attrs, & &1.filterable?)
  end

  @doc """
  Gets all sortable attributes.
  """
  def sortable_attributes(%__MODULE__{attributes: attrs}) do
    Enum.filter(attrs, & &1.sortable?)
  end

  @doc """
  Gets all attributes that should show in table view.
  """
  def table_attributes(%__MODULE__{attributes: attrs}) do
    Enum.filter(attrs, & &1.show_in_table?)
  end

  @doc """
  Gets all attributes that should show in forms.
  """
  def form_attributes(%__MODULE__{attributes: attrs}) do
    Enum.filter(attrs, & &1.show_in_form?)
  end

  @doc """
  Gets all relationships of a specific type.
  """
  def relationships_of_type(%__MODULE__{relationships: rels}, type) do
    Enum.filter(rels, &(&1.type == type))
  end

  @doc """
  Gets all actions of a specific type.
  """
  def actions_of_type(%__MODULE__{actions: actions}, type) do
    Enum.filter(actions, &(&1.type == type))
  end

  # Private helpers

  defp default_name(resource) do
    resource
    |> Module.split()
    |> List.last()
    |> format_name()
  end

  defp default_plural_name(resource) do
    name = default_name(resource)
    pluralize(name)
  end

  defp default_short_name(resource) do
    resource
    |> Module.split()
    |> List.last()
    |> String.downcase()
  end

  defp format_name(name) do
    name
    |> String.replace(~r/([A-Z])/, " \\1")
    |> String.trim()
  end

  defp pluralize(name) do
    # Simple pluralization - can be enhanced with a library
    cond do
      String.ends_with?(name, "y") ->
        String.slice(name, 0..-2//1) <> "ies"

      String.ends_with?(name, ["s", "x", "z", "ch", "sh"]) ->
        name <> "es"

      true ->
        name <> "s"
    end
  end

  defp guess_display_field do
    # Common fields to use for display in order of preference
    [:name, :title, :display_name, :email, :username, :id]
    |> Enum.at(0)
  end
end
