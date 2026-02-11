defmodule AshPanel.Schema.FilterDefinition do
  @moduledoc """
  Defines a filterable field and its behavior.

  Filter definitions are auto-generated from Ash resource attributes
  or can be manually defined for custom filtering logic.
  """

  defstruct [
    :field,
    :operator,
    :type,
    :options,
    :label,
    :placeholder
  ]

  @type filter_type :: :search | :select | :date_range | :number | :boolean
  @type operator :: :equals | :contains | :gte | :lte | :gt | :lt | :in | :range

  @type t :: %__MODULE__{
          field: atom(),
          operator: operator(),
          type: filter_type(),
          options: list() | nil,
          label: String.t() | nil,
          placeholder: String.t() | nil
        }

  @doc """
  Creates a new filter definition.

  ## Examples

      iex> FilterDefinition.new(:email, :contains, :search)
      %FilterDefinition{
        field: :email,
        operator: :contains,
        type: :search,
        label: "Email",
        placeholder: "Search..."
      }
  """
  def new(field, operator, type, opts \\ []) do
    %__MODULE__{
      field: field,
      operator: operator,
      type: type,
      options: opts[:options],
      label: opts[:label] || format_label(field),
      placeholder: opts[:placeholder] || default_placeholder(type)
    }
  end

  defp format_label(field) do
    field
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp default_placeholder(:search), do: "Search..."
  defp default_placeholder(:select), do: "All"
  defp default_placeholder(:number), do: "Enter number"
  defp default_placeholder(:date_range), do: nil
  defp default_placeholder(:boolean), do: nil
  defp default_placeholder(_), do: "Enter value..."
end
