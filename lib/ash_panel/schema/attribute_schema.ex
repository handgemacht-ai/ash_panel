defmodule AshPanel.Schema.AttributeSchema do
  @moduledoc """
  Complete metadata for an Ash resource attribute.

  Holds all information needed to display, filter, sort, and edit an attribute
  in various UI contexts.
  """

  defstruct [
    :name,
    :type,
    :label,
    :description,
    :primary_key?,
    :public?,
    :private?,
    :writable?,
    :allow_nil?,
    :generated?,
    :default,
    :constraints,
    :filterable?,
    :sortable?,
    :searchable?,
    :show_in_table?,
    :show_in_form?,
    :show_in_detail?,
    :field_type,
    :component,
    :filter_component,
    :formatter,
    :validations
  ]

  @type t :: %__MODULE__{
          name: atom(),
          type: atom() | module(),
          label: String.t(),
          description: String.t() | nil,
          primary_key?: boolean(),
          public?: boolean(),
          private?: boolean(),
          writable?: boolean(),
          allow_nil?: boolean(),
          generated?: boolean(),
          default: any(),
          constraints: keyword(),
          filterable?: boolean(),
          sortable?: boolean(),
          searchable?: boolean(),
          show_in_table?: boolean(),
          show_in_form?: boolean(),
          show_in_detail?: boolean(),
          field_type: atom(),
          component: module() | nil,
          filter_component: module() | nil,
          formatter: (any() -> String.t()) | nil,
          validations: list()
        }

  @doc """
  Creates a new AttributeSchema from an Ash attribute.
  """
  def new(ash_attribute, opts \\ []) do
    attr_private? = attribute_private?(ash_attribute)
    attr_public? = attribute_public?(ash_attribute)

    %__MODULE__{
      name: ash_attribute.name,
      type: ash_attribute.type,
      label: Keyword.get(opts, :label, format_label(ash_attribute.name)),
      description: Keyword.get(opts, :description, ash_attribute.description),
      primary_key?: Keyword.get(opts, :primary_key?, ash_attribute.primary_key?),
      public?: Keyword.get(opts, :public?, attr_public?),
      private?: Keyword.get(opts, :private?, attr_private?),
      writable?: Keyword.get(opts, :writable?, is_writable?(ash_attribute)),
      allow_nil?: Keyword.get(opts, :allow_nil?, ash_attribute.allow_nil?),
      generated?: Keyword.get(opts, :generated?, ash_attribute.generated?),
      default: Keyword.get(opts, :default, ash_attribute.default),
      constraints: Keyword.get(opts, :constraints, ash_attribute.constraints),
      filterable?: Keyword.get(opts, :filterable?, is_filterable?(ash_attribute)),
      sortable?: Keyword.get(opts, :sortable?, is_sortable?(ash_attribute)),
      searchable?: Keyword.get(opts, :searchable?, is_searchable?(ash_attribute)),
      show_in_table?: Keyword.get(opts, :show_in_table?, should_show_in_table?(ash_attribute)),
      show_in_form?: Keyword.get(opts, :show_in_form?, should_show_in_form?(ash_attribute)),
      show_in_detail?: Keyword.get(opts, :show_in_detail?, true),
      field_type: Keyword.get(opts, :field_type, infer_field_type(ash_attribute.type)),
      component: Keyword.get(opts, :component),
      filter_component: Keyword.get(opts, :filter_component),
      formatter: Keyword.get(opts, :formatter, default_formatter(ash_attribute.type)),
      validations: Keyword.get(opts, :validations, [])
    }
  end

  @doc """
  Updates an attribute schema with overrides.
  """
  def override(%__MODULE__{} = schema, overrides) when is_map(overrides) do
    struct(schema, overrides)
  end

  @doc """
  Checks if attribute is editable (writable and not generated).
  """
  def editable?(%__MODULE__{writable?: writable?, generated?: generated?}) do
    writable? && !generated?
  end

  @doc """
  Checks if attribute is required (not allow_nil and no default).
  """
  def required?(%__MODULE__{allow_nil?: allow_nil?, default: default}) do
    !allow_nil? && is_nil(default)
  end

  # Private helpers

  defp format_label(name) do
    name
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp is_writable?(ash_attribute) do
    !attribute_private?(ash_attribute) && !ash_attribute.generated?
  end

  defp is_filterable?(ash_attribute) do
    # Most attributes are filterable except very large text fields, binaries, etc.
    !attribute_private?(ash_attribute) && ash_attribute.type not in [:binary, :term]
  end

  defp is_sortable?(ash_attribute) do
    # Most attributes are sortable
    !attribute_private?(ash_attribute) && ash_attribute.type not in [:binary, :term, :map]
  end

  defp is_searchable?(ash_attribute) do
    # Only text-like fields are searchable
    !attribute_private?(ash_attribute) && string_like?(ash_attribute.type)
  end

  defp should_show_in_table?(ash_attribute) do
    # Don't show private, generated timestamps, or very large fields by default
    !attribute_private?(ash_attribute) &&
      !is_timestamp_field?(ash_attribute.name) &&
      !is_large_field?(ash_attribute.type)
  end

  defp should_show_in_form?(ash_attribute) do
    # Show if writable and not a timestamp
    !attribute_private?(ash_attribute) &&
      !ash_attribute.generated? &&
      !is_timestamp_field?(ash_attribute.name)
  end

  defp is_timestamp_field?(name) do
    name in [:inserted_at, :updated_at, :created_at, :modified_at]
  end

  defp is_large_field?(type) do
    type in [:binary, :term, :map]
  end

  defp string_like?(type) when is_atom(type) do
    type in [:string, :ci_string, :atom]
  end

  defp string_like?(type) do
    type in [Ash.Type.String, Ash.Type.CiString, Ash.Type.Atom]
  end

  defp attribute_private?(ash_attribute) do
    Map.get(ash_attribute, :private?, !Map.get(ash_attribute, :public?, true))
  end

  defp attribute_public?(ash_attribute) do
    Map.get(ash_attribute, :public?, !attribute_private?(ash_attribute))
  end

  defp infer_field_type(type) when is_atom(type) do
    case type do
      :string -> :text_input
      :ci_string -> :text_input
      :integer -> :number_input
      :float -> :number_input
      :decimal -> :number_input
      :boolean -> :checkbox
      :atom -> :select
      :date -> :date_input
      :time -> :time_input
      :datetime -> :datetime_input
      :utc_datetime -> :datetime_input
      :utc_datetime_usec -> :datetime_input
      :uuid -> :text_input
      :binary -> :file_input
      :map -> :json_editor
      :term -> :json_editor
      _ -> :text_input
    end
  end

  defp infer_field_type(type_module) do
    cond do
      type_module == Ash.Type.String -> :text_input
      type_module == Ash.Type.CiString -> :text_input
      type_module == Ash.Type.Integer -> :number_input
      type_module == Ash.Type.Float -> :number_input
      type_module == Ash.Type.Decimal -> :number_input
      type_module == Ash.Type.Boolean -> :checkbox
      type_module == Ash.Type.Atom -> :select
      type_module == Ash.Type.Date -> :date_input
      type_module == Ash.Type.UtcDatetime -> :datetime_input
      type_module == Ash.Type.UtcDatetimeUsec -> :datetime_input
      type_module == Ash.Type.UUID -> :text_input
      true -> :text_input
    end
  end

  defp default_formatter(type) when is_atom(type) do
    case type do
      :boolean -> &format_boolean/1
      :date -> &format_date/1
      :datetime -> &format_datetime/1
      :utc_datetime -> &format_datetime/1
      :utc_datetime_usec -> &format_datetime/1
      _ -> nil
    end
  end

  defp default_formatter(_type), do: nil

  defp format_boolean(true), do: "Yes"
  defp format_boolean(false), do: "No"
  defp format_boolean(nil), do: "-"

  defp format_date(%Date{} = date), do: Date.to_string(date)
  defp format_date(nil), do: "-"
  defp format_date(other), do: to_string(other)

  defp format_datetime(%DateTime{} = dt) do
    Calendar.strftime(dt, "%b %d, %Y %H:%M")
  end

  defp format_datetime(%NaiveDateTime{} = dt) do
    Calendar.strftime(dt, "%b %d, %Y %H:%M")
  end

  defp format_datetime(nil), do: "-"
  defp format_datetime(other), do: to_string(other)
end
