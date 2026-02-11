defmodule AshPanel.Navigation do
  @moduledoc """
  Helpers for building navigation menus from AshPanel resources.

  This module provides utilities for creating sidebar menus, breadcrumbs,
  and other navigation elements based on your resources.

  ## Usage

      # Define your resources
      resources = [
        %{
          resource: MyApp.Accounts.User,
          domain: MyApp.Accounts,
          path: "/admin/users",
          label: "Users",
          icon: "users"
        },
        %{
          resource: MyApp.Blog.Post,
          domain: MyApp.Blog,
          path: "/admin/posts",
          label: "Posts",
          icon: "document"
        }
      ]

      # In your layout component
      <nav>
        <%= for item <- AshPanel.Navigation.menu_items(resources, @current_path) do %>
          <a href={item.path} class={item.active_class}>
            {item.label}
          </a>
        <% end %>
      </nav>
  """

  @doc """
  Builds menu items from a list of resource configurations.

  Returns a list of maps with:
  - `label` - Display name
  - `path` - Route path
  - `active?` - Whether this item is currently active
  - `icon` - Optional icon name
  - `resource` - Resource module
  - `domain` - Domain module

  ## Options

  - `current_path` - Current path to determine active state
  - `base_path` - Base path prefix (default: "/admin")

  ## Example

      resources = [
        %{resource: User, domain: Accounts, label: "Users"},
        %{resource: Post, domain: Blog, label: "Posts"}
      ]

      AshPanel.Navigation.menu_items(resources, "/admin/users")
      #=> [
      #     %{label: "Users", path: "/admin/users", active?: true, ...},
      #     %{label: "Posts", path: "/admin/posts", active?: false, ...}
      #   ]
  """
  def menu_items(resources, current_path \\ nil, opts \\ []) do
    base_path = Keyword.get(opts, :base_path, "/admin")

    Enum.map(resources, fn resource ->
      path = Map.get(resource, :path) || build_path(base_path, resource)
      label = Map.get(resource, :label) || infer_label(resource)

      %{
        label: label,
        path: path,
        active?: path_active?(path, current_path),
        icon: Map.get(resource, :icon),
        resource: Map.get(resource, :resource),
        domain: Map.get(resource, :domain)
      }
    end)
  end

  @doc """
  Builds breadcrumb navigation for a resource view.

  ## Examples

      AshPanel.Navigation.breadcrumbs(
        resource: User,
        domain: Accounts,
        action: :show,
        record: user,
        base_path: "/admin"
      )
      #=> [
      #     %{label: "Admin", path: "/admin"},
      #     %{label: "Users", path: "/admin/users"},
      #     %{label: "John Doe", path: nil}
      #   ]
  """
  def breadcrumbs(opts) do
    resource = Keyword.fetch!(opts, :resource)
    action = Keyword.get(opts, :action, :index)
    record = Keyword.get(opts, :record)
    base_path = Keyword.get(opts, :base_path, "/admin")
    resource_path = Keyword.get(opts, :resource_path) || build_resource_path(base_path, resource)

    crumbs = [
      %{label: "Admin", path: base_path}
    ]

    resource_label = infer_label_plural(resource)

    crumbs =
      case action do
        :index ->
          crumbs ++ [%{label: resource_label, path: nil}]

        :new ->
          crumbs ++
            [
              %{label: resource_label, path: resource_path},
              %{label: "New", path: nil}
            ]

        :show ->
          record_label = if record, do: get_display_name(record), else: "View"

          crumbs ++
            [
              %{label: resource_label, path: resource_path},
              %{label: record_label, path: nil}
            ]

        :edit ->
          record_label = if record, do: get_display_name(record), else: "Edit"

          crumbs ++
            [
              %{label: resource_label, path: resource_path},
              %{label: record_label, path: nil}
            ]

        _ ->
          crumbs ++ [%{label: resource_label, path: nil}]
      end

    crumbs
  end

  @doc """
  Groups resources by category for nested navigation.

  ## Example

      resources = [
        %{resource: User, category: "Accounts"},
        %{resource: Role, category: "Accounts"},
        %{resource: Post, category: "Content"}
      ]

      AshPanel.Navigation.grouped_menu(resources)
      #=> %{
      #     "Accounts" => [%{resource: User, ...}, %{resource: Role, ...}],
      #     "Content" => [%{resource: Post, ...}]
      #   }
  """
  def grouped_menu(resources) do
    resources
    |> Enum.group_by(fn resource ->
      Map.get(resource, :category, "General")
    end)
  end

  # Private helpers

  defp build_path(base_path, %{resource: resource}) do
    "#{base_path}/#{resource_slug(resource)}"
  end

  defp build_resource_path(base_path, resource) do
    "#{base_path}/#{resource_slug(resource)}"
  end

  defp resource_slug(resource) do
    resource
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
    |> Inflex.pluralize()
  end

  defp infer_label(%{resource: resource}) do
    resource
    |> Module.split()
    |> List.last()
    |> Phoenix.Naming.humanize()
  end

  defp infer_label(resource) when is_atom(resource) do
    resource
    |> Module.split()
    |> List.last()
    |> Phoenix.Naming.humanize()
  end

  defp infer_label_plural(resource) do
    resource
    |> infer_label()
    |> Inflex.pluralize()
  end

  defp path_active?(item_path, current_path)
       when is_binary(item_path) and is_binary(current_path) do
    String.starts_with?(current_path, item_path)
  end

  defp path_active?(_, _), do: false

  defp get_display_name(%{name: name}) when is_binary(name), do: name
  defp get_display_name(%{title: title}) when is_binary(title), do: title
  defp get_display_name(%{email: email}) when is_binary(email), do: email

  defp get_display_name(%{id: id}) when is_binary(id) or is_integer(id) do
    "##{id}"
  end

  defp get_display_name(_), do: "View"
end
