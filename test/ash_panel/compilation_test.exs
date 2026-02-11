defmodule AshPanel.CompilationTest do
  use ExUnit.Case

  @moduletag :compilation

  # Test resource and domain for compilation tests
  defmodule TestResource do
    use Ash.Resource,
      domain: TestDomain,
      data_layer: Ash.DataLayer.Ets

    attributes do
      uuid_primary_key(:id)
      attribute(:name, :string, public?: true)
      attribute(:category, :string, public?: true)
    end

    actions do
      default_accept([:name, :category])
      defaults([:read, :destroy, create: :*, update: :*])
    end
  end

  defmodule TestDomain do
    use Ash.Domain

    resources do
      resource(TestResource)
    end
  end

  describe "compilation warnings" do
    @tag :slow
    test "compiling LiveView with all views produces no critical warnings" do
      # Define a module with all views enabled
      code =
        quote do
          defmodule AshPanel.CompilationTest.AllViewsLive do
            use Phoenix.LiveView

            use AshPanel.LiveView,
              resource: AshPanel.CompilationTest.TestResource,
              domain: AshPanel.CompilationTest.TestDomain,
              views: [:list, :detail, :form]
          end
        end

      # Compile the module and capture IO
      output =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          Code.compile_quoted(code)
        end)

      # Should not have warnings about:
      # - negative steps in String.slice
      # - unreachable clauses for helper functions
      # - typing violations in computer generators
      refute output =~ "negative steps are not supported in String.slice",
             "Found negative step warning in compilation output:\n#{output}"

      refute output =~ "cannot match because a previous clause",
             "Found unreachable clause warning in compilation output:\n#{output}"

      refute output =~ "expected a 0-arity function",
             "Found 0-arity typing violation in compilation output:\n#{output}"

      refute output =~ "expected a 1-arity function",
             "Found 1-arity typing violation in compilation output:\n#{output}"
    end

    test "resource schema pluralization compiles without warnings" do
      alias AshPanel.Schema.ResourceSchema

      # This should not produce warnings about negative steps
      output =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          # Test all pluralization paths
          ResourceSchema.new(TestResource, TestDomain, name: "Category")
          ResourceSchema.new(TestResource, TestDomain, name: "Status")
          ResourceSchema.new(TestResource, TestDomain, name: "User")
        end)

      refute output =~ "negative steps",
             "Found negative step warning when creating resource schemas:\n#{output}"
    end

    test "list computer with default options compiles without typing warnings" do
      code =
        quote do
          defmodule AshPanel.CompilationTest.DefaultListLive do
            use Phoenix.LiveView

            use AshPanel.LiveView,
              resource: AshPanel.CompilationTest.TestResource,
              domain: AshPanel.CompilationTest.TestDomain,
              views: [:list]
          end
        end

      output =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          Code.compile_quoted(code)
        end)

      refute output =~ "expected a 0-arity function",
             "Found 0-arity typing violation with default list options:\n#{output}"

      refute output =~ "expected a 1-arity function",
             "Found 1-arity typing violation with default list options:\n#{output}"
    end

    test "helper functions compile without unreachable clause warnings" do
      code =
        quote do
          defmodule AshPanel.CompilationTest.HelperTestLive do
            use Phoenix.LiveView

            use AshPanel.LiveView,
              resource: AshPanel.CompilationTest.TestResource,
              domain: AshPanel.CompilationTest.TestDomain,
              views: [:list, :detail, :form]
          end
        end

      output =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          Code.compile_quoted(code)
        end)

      # Should not have warnings about unreachable clauses for any helper functions
      refute output =~
               ~r/this clause for (refresh_list|show_detail|show_create_form|show_edit_form).*cannot match/,
             "Found unreachable clause warning for helper functions:\n#{output}"
    end
  end

  describe "functional compilation" do
    test "all LiveView components compile successfully" do
      # Test that we can actually compile a full LiveView with all features
      defmodule FullFeaturedLive do
        use Phoenix.LiveView

        use AshPanel.LiveView,
          resource: AshPanel.CompilationTest.TestResource,
          domain: AshPanel.CompilationTest.TestDomain,
          views: [:list, :detail, :form],
          list: [
            base_query_fun: fn _actor -> nil end,
            page_size: 25
          ]
      end

      # Verify basic functionality
      assert FullFeaturedLive
      assert function_exported?(FullFeaturedLive, :mount, 3)
      assert function_exported?(FullFeaturedLive, :refresh_list, 1)
      assert function_exported?(FullFeaturedLive, :show_detail, 2)
      assert function_exported?(FullFeaturedLive, :show_create_form, 1)
      assert function_exported?(FullFeaturedLive, :show_edit_form, 2)
    end
  end
end
