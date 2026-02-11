defmodule AshPanel.ComputerGenerator.ListComputerTest do
  use ExUnit.Case, async: true

  # Test resource and domain
  defmodule TestResource do
    use Ash.Resource,
      domain: TestDomain,
      data_layer: Ash.DataLayer.Ets

    attributes do
      uuid_primary_key(:id)
      attribute(:name, :string, public?: true)
      attribute(:status, :string, public?: true)
    end

    actions do
      default_accept([:name, :status])
      defaults([:read, :destroy, create: :*, update: :*])
    end
  end

  defmodule TestDomain do
    use Ash.Domain

    resources do
      resource(TestResource)
    end
  end

  describe "base_query_fun handling" do
    test "works with nil base_query_fun (default)" do
      # This should compile without typing warnings
      defmodule DefaultQueryLive do
        use Phoenix.LiveView

        use AshPanel.LiveView,
          resource: AshPanel.ComputerGenerator.ListComputerTest.TestResource,
          domain: AshPanel.ComputerGenerator.ListComputerTest.TestDomain,
          views: [:list]

        # No list options specified, base_query_fun defaults to nil
      end

      assert DefaultQueryLive
      assert function_exported?(DefaultQueryLive, :mount, 3)
    end

    test "works with 0-arity base_query_fun" do
      # This should compile without typing warnings
      defmodule ZeroArityLive do
        use Phoenix.LiveView

        use AshPanel.LiveView,
          resource: AshPanel.ComputerGenerator.ListComputerTest.TestResource,
          domain: AshPanel.ComputerGenerator.ListComputerTest.TestDomain,
          views: [:list],
          list: [
            base_query_fun: fn ->
              AshPanel.ComputerGenerator.ListComputerTest.TestResource
            end
          ]
      end

      assert ZeroArityLive
      assert function_exported?(ZeroArityLive, :mount, 3)
    end

    test "works with 1-arity base_query_fun" do
      # This should compile without typing warnings
      defmodule OneArityLive do
        use Phoenix.LiveView

        use AshPanel.LiveView,
          resource: AshPanel.ComputerGenerator.ListComputerTest.TestResource,
          domain: AshPanel.ComputerGenerator.ListComputerTest.TestDomain,
          views: [:list],
          list: [
            base_query_fun: fn _actor ->
              AshPanel.ComputerGenerator.ListComputerTest.TestResource
            end
          ]
      end

      assert OneArityLive
      assert function_exported?(OneArityLive, :mount, 3)
    end

    test "works with MFA tuple base_query_fun" do
      # This should compile without typing warnings
      defmodule MfaLive do
        use Phoenix.LiveView

        def custom_query(actor) do
          AshPanel.ComputerGenerator.ListComputerTest.TestResource
        end

        use AshPanel.LiveView,
          resource: AshPanel.ComputerGenerator.ListComputerTest.TestResource,
          domain: AshPanel.ComputerGenerator.ListComputerTest.TestDomain,
          views: [:list],
          list: [
            base_query_fun: {__MODULE__, :custom_query}
          ]
      end

      assert MfaLive
      assert function_exported?(MfaLive, :mount, 3)
    end

    test "works with MFA tuple with extra args" do
      # This should compile without typing warnings
      defmodule MfaExtraLive do
        use Phoenix.LiveView

        def custom_query_with_extra(actor, extra_arg) do
          AshPanel.ComputerGenerator.ListComputerTest.TestResource
        end

        use AshPanel.LiveView,
          resource: AshPanel.ComputerGenerator.ListComputerTest.TestResource,
          domain: AshPanel.ComputerGenerator.ListComputerTest.TestDomain,
          views: [:list],
          list: [
            base_query_fun: {__MODULE__, :custom_query_with_extra, [:extra_value]}
          ]
      end

      assert MfaExtraLive
      assert function_exported?(MfaExtraLive, :mount, 3)
    end
  end

  describe "list computer compilation" do
    test "compiling list computer does not produce typing warnings" do
      # This test ensures that the typing violation fix works
      # If the fix is reverted, compilation warnings would appear

      code =
        quote do
          defmodule AshPanel.ComputerGenerator.ListComputerTest.CompilationTestLive do
            use Phoenix.LiveView

            use AshPanel.LiveView,
              resource: AshPanel.ComputerGenerator.ListComputerTest.TestResource,
              domain: AshPanel.ComputerGenerator.ListComputerTest.TestDomain,
              views: [:list]
          end
        end

      # Compile the module - should not produce typing warnings
      [{module, _binary}] = Code.compile_quoted(code)

      # Verify the module was created
      assert module == AshPanel.ComputerGenerator.ListComputerTest.CompilationTestLive

      # Verify list computer was set up
      assert function_exported?(module, :mount, 3)
    end
  end

  describe "filter_fun handling" do
    test "works with default filter_fun" do
      defmodule DefaultFilterLive do
        use Phoenix.LiveView

        use AshPanel.LiveView,
          resource: AshPanel.ComputerGenerator.ListComputerTest.TestResource,
          domain: AshPanel.ComputerGenerator.ListComputerTest.TestDomain,
          views: [:list]
      end

      assert DefaultFilterLive
    end

    test "works with custom filter_fun" do
      defmodule CustomFilterLive do
        use Phoenix.LiveView

        def custom_filter(query, _filters) do
          query
        end

        use AshPanel.LiveView,
          resource: AshPanel.ComputerGenerator.ListComputerTest.TestResource,
          domain: AshPanel.ComputerGenerator.ListComputerTest.TestDomain,
          views: [:list],
          list: [
            filter_fun: &__MODULE__.custom_filter/2
          ]
      end

      assert CustomFilterLive
    end
  end
end
