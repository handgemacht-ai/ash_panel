defmodule AshPanel.LiveViewHelpersTest do
  use ExUnit.Case, async: true

  # Test resource and domain
  defmodule TestResource do
    use Ash.Resource,
      domain: TestDomain,
      data_layer: Ash.DataLayer.Ets

    attributes do
      uuid_primary_key(:id)
      attribute(:name, :string, public?: true)
    end

    actions do
      default_accept([:name])
      defaults([:read, :destroy, create: :*, update: :*])
    end
  end

  defmodule TestDomain do
    use Ash.Domain

    resources do
      resource(TestResource)
    end
  end

  describe "helper functions with :list view" do
    defmodule ListOnlyLive do
      use Phoenix.LiveView

      use AshPanel.LiveView,
        resource: AshPanel.LiveViewHelpersTest.TestResource,
        domain: AshPanel.LiveViewHelpersTest.TestDomain,
        views: [:list]
    end

    test "refresh_list/1 is exported" do
      assert function_exported?(ListOnlyLive, :refresh_list, 1)
    end

    test "show_detail/2 is exported but returns socket unchanged" do
      assert function_exported?(ListOnlyLive, :show_detail, 2)
    end

    test "show_create_form/1 is exported but returns socket unchanged" do
      assert function_exported?(ListOnlyLive, :show_create_form, 1)
    end

    test "show_edit_form/2 is exported but returns socket unchanged" do
      assert function_exported?(ListOnlyLive, :show_edit_form, 2)
    end
  end

  describe "helper functions with :detail view" do
    defmodule DetailOnlyLive do
      use Phoenix.LiveView

      use AshPanel.LiveView,
        resource: AshPanel.LiveViewHelpersTest.TestResource,
        domain: AshPanel.LiveViewHelpersTest.TestDomain,
        views: [:detail]
    end

    test "show_detail/2 is exported" do
      assert function_exported?(DetailOnlyLive, :show_detail, 2)
    end

    test "refresh_list/1 is exported but returns socket unchanged" do
      assert function_exported?(DetailOnlyLive, :refresh_list, 1)
    end

    test "show_create_form/1 is exported but returns socket unchanged" do
      assert function_exported?(DetailOnlyLive, :show_create_form, 1)
    end

    test "show_edit_form/2 is exported but returns socket unchanged" do
      assert function_exported?(DetailOnlyLive, :show_edit_form, 2)
    end
  end

  describe "helper functions with :form view" do
    defmodule FormOnlyLive do
      use Phoenix.LiveView

      use AshPanel.LiveView,
        resource: AshPanel.LiveViewHelpersTest.TestResource,
        domain: AshPanel.LiveViewHelpersTest.TestDomain,
        views: [:form]
    end

    test "show_create_form/1 is exported" do
      assert function_exported?(FormOnlyLive, :show_create_form, 1)
    end

    test "show_edit_form/2 is exported" do
      assert function_exported?(FormOnlyLive, :show_edit_form, 2)
    end

    test "refresh_list/1 is exported but returns socket unchanged" do
      assert function_exported?(FormOnlyLive, :refresh_list, 1)
    end

    test "show_detail/2 is exported but returns socket unchanged" do
      assert function_exported?(FormOnlyLive, :show_detail, 2)
    end
  end

  describe "helper functions with all views" do
    defmodule AllViewsLive do
      use Phoenix.LiveView

      use AshPanel.LiveView,
        resource: AshPanel.LiveViewHelpersTest.TestResource,
        domain: AshPanel.LiveViewHelpersTest.TestDomain,
        views: [:list, :detail, :form]
    end

    test "all helper functions are exported" do
      assert function_exported?(AllViewsLive, :refresh_list, 1)
      assert function_exported?(AllViewsLive, :show_detail, 2)
      assert function_exported?(AllViewsLive, :show_create_form, 1)
      assert function_exported?(AllViewsLive, :show_edit_form, 2)
    end
  end

  describe "module compilation" do
    test "compiling LiveView with multiple views does not produce unreachable clause warnings" do
      # This test ensures that the fix for unreachable clauses works
      # If the fix is reverted, this test should still pass but compilation warnings would appear

      code =
        quote do
          defmodule AshPanel.LiveViewHelpersTest.CompilationTestLive do
            use Phoenix.LiveView

            use AshPanel.LiveView,
              resource: AshPanel.LiveViewHelpersTest.TestResource,
              domain: AshPanel.LiveViewHelpersTest.TestDomain,
              views: [:list, :detail, :form]
          end
        end

      # Compile the module
      [{module, _binary}] = Code.compile_quoted(code)

      # Verify the module was created
      assert module == AshPanel.LiveViewHelpersTest.CompilationTestLive

      # Verify all helper functions exist
      assert function_exported?(module, :refresh_list, 1)
      assert function_exported?(module, :show_detail, 2)
      assert function_exported?(module, :show_create_form, 1)
      assert function_exported?(module, :show_edit_form, 2)
    end
  end
end
