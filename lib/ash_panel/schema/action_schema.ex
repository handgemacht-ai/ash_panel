defmodule AshPanel.Schema.ActionSchema do
  @moduledoc """
  Metadata for an Ash resource action.

  Holds information about create, read, update, destroy, and custom actions.
  """

  defstruct [
    :name,
    :type,
    :label,
    :description,
    :primary?,
    :public?,
    :arguments,
    :changes,
    :icon,
    :button_text,
    :confirmation_message,
    :success_message,
    :requires_input?
  ]

  @type action_type :: :create | :read | :update | :destroy | :action

  @type t :: %__MODULE__{
          name: atom(),
          type: action_type(),
          label: String.t(),
          description: String.t() | nil,
          primary?: boolean(),
          public?: boolean(),
          arguments: list(map()),
          changes: list(),
          icon: String.t() | nil,
          button_text: String.t() | nil,
          confirmation_message: String.t() | nil,
          success_message: String.t() | nil,
          requires_input?: boolean()
        }

  @doc """
  Creates a new ActionSchema from an Ash action.
  """
  def new(ash_action, opts \\ []) do
    %__MODULE__{
      name: ash_action.name,
      type: ash_action.type,
      label: Keyword.get(opts, :label, format_label(ash_action.name)),
      description: Keyword.get(opts, :description, ash_action.description),
      primary?: Keyword.get(opts, :primary?, Map.get(ash_action, :primary?, false)),
      public?: Keyword.get(opts, :public?, !Map.get(ash_action, :private?, false)),
      arguments: Keyword.get(opts, :arguments, Map.get(ash_action, :arguments, [])),
      changes: Keyword.get(opts, :changes, Map.get(ash_action, :changes, [])),
      icon: Keyword.get(opts, :icon, default_icon(ash_action.type)),
      button_text: Keyword.get(opts, :button_text, format_button_text(ash_action)),
      confirmation_message: Keyword.get(opts, :confirmation_message),
      success_message: Keyword.get(opts, :success_message),
      requires_input?: Keyword.get(opts, :requires_input?, has_required_arguments?(ash_action))
    }
  end

  @doc """
  Updates an action schema with overrides.
  """
  def override(%__MODULE__{} = schema, overrides) when is_map(overrides) do
    struct(schema, overrides)
  end

  @doc """
  Checks if action is a standard CRUD action.
  """
  def crud_action?(%__MODULE__{type: type}), do: type in [:create, :read, :update, :destroy]

  @doc """
  Checks if action is a custom action.
  """
  def custom_action?(%__MODULE__{type: type}), do: type == :action

  @doc """
  Checks if action requires confirmation.
  """
  def requires_confirmation?(%__MODULE__{confirmation_message: msg}), do: !is_nil(msg)

  @doc """
  Checks if action is destructive (destroy or marked as dangerous).
  """
  def destructive?(%__MODULE__{type: :destroy}), do: true
  def destructive?(%__MODULE__{}), do: false

  # Private helpers

  defp format_label(name) do
    name
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp default_icon(:create), do: "hero-plus"
  defp default_icon(:read), do: "hero-eye"
  defp default_icon(:update), do: "hero-pencil"
  defp default_icon(:destroy), do: "hero-trash"
  defp default_icon(:action), do: "hero-bolt"

  defp format_button_text(%{type: :create}), do: "Create"
  defp format_button_text(%{type: :update}), do: "Update"
  defp format_button_text(%{type: :destroy}), do: "Delete"
  defp format_button_text(%{name: name}), do: format_label(name)

  defp has_required_arguments?(ash_action) do
    arguments = Map.get(ash_action, :arguments, [])

    Enum.any?(arguments, fn arg ->
      !Map.get(arg, :allow_nil?, true) && is_nil(Map.get(arg, :default))
    end)
  end
end
