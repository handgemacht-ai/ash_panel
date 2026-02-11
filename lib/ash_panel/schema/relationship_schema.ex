defmodule AshPanel.Schema.RelationshipSchema do
  @moduledoc """
  Metadata for an Ash resource relationship.

  Holds information about belongs_to, has_one, has_many, and many_to_many relationships.
  """

  defstruct [
    :name,
    :type,
    :destination,
    :source_attribute,
    :destination_attribute,
    :label,
    :description,
    :public?,
    :writable?,
    :required?,
    :cardinality,
    :show_in_table?,
    :show_in_form?,
    :show_in_detail?,
    :display_field,
    :sort
  ]

  @type relationship_type :: :belongs_to | :has_one | :has_many | :many_to_many

  @type t :: %__MODULE__{
          name: atom(),
          type: relationship_type(),
          destination: module(),
          source_attribute: atom() | nil,
          destination_attribute: atom() | nil,
          label: String.t(),
          description: String.t() | nil,
          public?: boolean(),
          writable?: boolean(),
          required?: boolean(),
          cardinality: :one | :many,
          show_in_table?: boolean(),
          show_in_form?: boolean(),
          show_in_detail?: boolean(),
          display_field: atom(),
          sort: keyword() | nil
        }

  @doc """
  Creates a new RelationshipSchema from an Ash relationship.
  """
  def new(ash_relationship, opts \\ []) do
    %__MODULE__{
      name: ash_relationship.name,
      type: ash_relationship.type,
      destination: ash_relationship.destination,
      source_attribute: ash_relationship.source_attribute,
      destination_attribute: ash_relationship.destination_attribute,
      label: Keyword.get(opts, :label, format_label(ash_relationship.name)),
      description: Keyword.get(opts, :description, ash_relationship.description),
      public?: Keyword.get(opts, :public?, !Map.get(ash_relationship, :private?, false)),
      writable?: Keyword.get(opts, :writable?, is_writable?(ash_relationship)),
      required?: Keyword.get(opts, :required?, Map.get(ash_relationship, :required?, false)),
      cardinality: Keyword.get(opts, :cardinality, infer_cardinality(ash_relationship.type)),
      show_in_table?: Keyword.get(opts, :show_in_table?, should_show_in_table?(ash_relationship)),
      show_in_form?: Keyword.get(opts, :show_in_form?, should_show_in_form?(ash_relationship)),
      show_in_detail?: Keyword.get(opts, :show_in_detail?, true),
      display_field: Keyword.get(opts, :display_field, :name),
      sort: Keyword.get(opts, :sort)
    }
  end

  @doc """
  Updates a relationship schema with overrides.
  """
  def override(%__MODULE__{} = schema, overrides) when is_map(overrides) do
    struct(schema, overrides)
  end

  @doc """
  Checks if relationship is a to-one relationship.
  """
  def to_one?(%__MODULE__{cardinality: cardinality}), do: cardinality == :one

  @doc """
  Checks if relationship is a to-many relationship.
  """
  def to_many?(%__MODULE__{cardinality: cardinality}), do: cardinality == :many

  # Private helpers

  defp format_label(name) do
    name
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp is_writable?(ash_relationship) do
    # Only belongs_to and many_to_many are typically writable in forms
    ash_relationship.type in [:belongs_to, :many_to_many] &&
      !Map.get(ash_relationship, :private?, false)
  end

  defp infer_cardinality(:belongs_to), do: :one
  defp infer_cardinality(:has_one), do: :one
  defp infer_cardinality(:has_many), do: :many
  defp infer_cardinality(:many_to_many), do: :many

  defp should_show_in_table?(ash_relationship) do
    # Only show belongs_to in tables by default (foreign key relationships)
    ash_relationship.type == :belongs_to &&
      !Map.get(ash_relationship, :private?, false)
  end

  defp should_show_in_form?(ash_relationship) do
    # Show belongs_to and many_to_many in forms
    ash_relationship.type in [:belongs_to, :many_to_many] &&
      !Map.get(ash_relationship, :private?, false)
  end
end
