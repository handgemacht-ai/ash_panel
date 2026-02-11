defmodule AshPanel.Router do
  @moduledoc """
  Router helpers for mounting AshPanel resources in your Phoenix router.

  ## Usage

  In your router:

      use AshPanel.Router

      scope "/admin" do
        pipe_through [:browser, :require_authenticated_user]

        ash_panel_resource "/users", MyAppWeb.Admin.UsersLive
        ash_panel_resource "/posts", MyAppWeb.Admin.PostsLive
      end

  This will generate standard RESTful routes:

      GET     /admin/users            UsersLive (live_action: :index)
      GET     /admin/users/new        UsersLive (live_action: :new)
      GET     /admin/users/:id        UsersLive (live_action: :show)
      GET     /admin/users/:id/edit   UsersLive (live_action: :edit)

  ## Options

  You can customize which routes are generated:

      ash_panel_resource "/users", MyAppWeb.Admin.UsersLive, only: [:index, :show]
      ash_panel_resource "/posts", MyAppWeb.Admin.PostsLive, except: [:edit]

  ## Creating the LiveView

  Create your LiveView using `AshPanel.ResourceLive`:

      defmodule MyAppWeb.Admin.UsersLive do
        use AshPanel.ResourceLive,
          resource: MyApp.Accounts.User,
          domain: MyApp.Accounts
      end

  That's it! The LiveView will automatically handle all CRUD operations.

  ## Authentication

  Since routes are defined within your scope, they inherit your pipe_through
  authentication:

      scope "/admin" do
        pipe_through [:browser, :require_authenticated_user]
        # These routes require authentication
      end
  """

  defmacro __using__(_opts) do
    quote do
      import AshPanel.Router, only: [ash_panel_resource: 2, ash_panel_resource: 3]
    end
  end

  @doc """
  Mounts routes for an AshPanel resource LiveView.

  ## Examples

      ash_panel_resource "/users", MyAppWeb.Admin.UsersLive
      ash_panel_resource "/posts", MyAppWeb.Admin.PostsLive, only: [:index, :show]
      ash_panel_resource "/comments", MyAppWeb.Admin.CommentsLive, except: [:edit]
      ash_panel_resource "/articles", MyAppWeb.Admin.PostsLive, param: :slug
  """
  defmacro ash_panel_resource(path, live_view_module, opts \\ []) do
    quote bind_quoted: [path: path, live_view_module: live_view_module, opts: opts] do
      actions = AshPanel.Router.resolve_actions(opts)
      param = Keyword.get(opts, :param, :id)

      # Index route
      if :index in actions do
        live(path, live_view_module, :index)
      end

      # New route
      if :new in actions do
        live("#{path}/new", live_view_module, :new)
      end

      # Show route
      if :show in actions do
        live("#{path}/:#{param}", live_view_module, :show)
      end

      # Edit route
      if :edit in actions do
        live("#{path}/:#{param}/edit", live_view_module, :edit)
      end
    end
  end

  @doc false
  def resolve_actions(opts) do
    only = Keyword.get(opts, :only)
    except = Keyword.get(opts, :except, [])

    all_actions = [:index, :show, :new, :edit]

    cond do
      only -> only
      except -> all_actions -- except
      true -> all_actions
    end
  end
end
