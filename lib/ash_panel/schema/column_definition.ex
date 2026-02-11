defmodule AshPanel.Schema.ColumnDefinition do
  @moduledoc """
  Defines a table column and its display behavior.

  Column definitions are auto-generated from Ash resource attributes
  or can be manually defined for custom display logic.
  """

  defstruct [
    :field,
    :label,
    :type,
    :sortable,
    :component,
    :formatter,
    :width,
    :align
  ]

  @type t :: %__MODULE__{
          field: atom(),
          label: String.t(),
          type: atom(),
          sortable: boolean(),
          component: module() | nil,
          formatter: (any() -> String.t()) | nil,
          width: String.t() | nil,
          align: :left | :center | :right
        }

  @doc """
  Creates a new column definition.

  ## Examples

      iex> ColumnDefinition.new(:email, :string)
      %ColumnDefinition{
        field: :email,
        label: "Email",
        type: :string,
        sortable: true,
        align: :left
      }
  """
  def new(field, type, opts \\ []) do
    %__MODULE__{
      field: field,
      label: opts[:label] || format_label(field),
      type: type,
      sortable: opts[:sortable] != false,
      component: opts[:component],
      formatter: opts[:formatter],
      width: opts[:width],
      align: opts[:align] || default_align(type)
    }
  end

  defp format_label(field) do
    field
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp default_align(:integer), do: :right
  defp default_align(:float), do: :right
  defp default_align(:decimal), do: :right
  defp default_align(_), do: :left
end
