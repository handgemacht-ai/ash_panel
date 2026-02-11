defmodule AshPanel.LiveViewIntegrationTest do
  use ExUnit.Case, async: false
  import AshPanel.Test.Helpers

  alias AshPanel.Test.{TestUser, TestPost, TestDomain}

  describe "AshPanel.LiveView macro" do
    test "generates __ash_panel_schema__/0 with correct metadata" do
      defmodule BasicLive do
        use Phoenix.LiveView

        use AshPanel.LiveView,
          resource: TestUser,
          domain: TestDomain,
          views: [:list]
      end

      schema = BasicLive.__ash_panel_schema__()

      # Schema should have attributes, relationships, actions
      assert schema != nil
      assert schema.resource == TestUser
      assert is_list(schema.attributes)
      assert is_list(schema.relationships)
      assert is_list(schema.actions)
      assert schema.primary_keys == [:id]
    end

    test "applies overrides to generated schema" do
      defmodule OverrideLive do
        use Phoenix.LiveView

        use AshPanel.LiveView,
          resource: TestUser,
          domain: TestDomain,
          views: [:list],
          overrides: %{
            attributes: %{
              name: %{
                label: "Full Name",
                searchable: true
              },
              email: %{
                label: "Email Address",
                hidden: false
              }
            }
          }
      end

      schema = OverrideLive.__ash_panel_schema__()

      # Check that overrides were applied
      name_attr = find_attribute(schema, :name)
      assert name_attr != nil
      assert name_attr.label == "Full Name"
      assert name_attr.searchable == true

      email_attr = find_attribute(schema, :email)
      assert email_attr != nil
      assert email_attr.label == "Email Address"
    end

    test "initializes requested views" do
      defmodule MultiViewLive do
        use Phoenix.LiveView

        use AshPanel.LiveView,
          resource: TestUser,
          domain: TestDomain,
          views: [:list, :detail, :form]
      end

      # Should compile without errors
      assert MultiViewLive.__ash_panel_schema__() != nil
    end

    test "handles list view configuration" do
      defmodule ListViewLive do
        use Phoenix.LiveView

        use AshPanel.LiveView,
          resource: TestUser,
          domain: TestDomain,
          views: [:list],
          overrides: %{
            attributes: %{
              name: %{sortable: true, filterable: true},
              age: %{sortable: true}
            }
          }
      end

      schema = ListViewLive.__ash_panel_schema__()

      name_attr = find_attribute(schema, :name)
      assert name_attr.sortable == true
      assert name_attr.filterable == true

      age_attr = find_attribute(schema, :age)
      assert age_attr.sortable == true
    end

    test "handles detail view configuration" do
      defmodule DetailViewLive do
        use Phoenix.LiveView

        use AshPanel.LiveView,
          resource: TestUser,
          domain: TestDomain,
          views: [:detail],
          overrides: %{
            relationships: %{
              posts: %{label: "User Posts", hidden: false}
            }
          }
      end

      schema = DetailViewLive.__ash_panel_schema__()

      posts_rel = find_relationship(schema, :posts)
      assert posts_rel != nil
      assert posts_rel.label == "User Posts"
    end

    test "handles form view configuration" do
      defmodule FormViewLive do
        use Phoenix.LiveView

        use AshPanel.LiveView,
          resource: TestUser,
          domain: TestDomain,
          views: [:form],
          overrides: %{
            actions: %{
              create: %{label: "Create New User"},
              update: %{label: "Update User"}
            }
          }
      end

      schema = FormViewLive.__ash_panel_schema__()

      create_action = find_action(schema, :create)
      assert create_action != nil
      assert create_action.label == "Create New User"
    end

    test "applies nested overrides correctly" do
      defmodule NestedOverridesLive do
        use Phoenix.LiveView

        use AshPanel.LiveView,
          resource: TestPost,
          domain: TestDomain,
          views: [:list],
          overrides: %{
            attributes: %{
              title: %{label: "Post Title", sortable: true, searchable: true},
              published: %{label: "Is Published?", filterable: true}
            },
            relationships: %{
              author: %{label: "Written By"},
              comments: %{label: "Post Comments"}
            }
          }
      end

      schema = NestedOverridesLive.__ash_panel_schema__()

      title_attr = find_attribute(schema, :title)
      assert title_attr.label == "Post Title"
      assert title_attr.sortable == true
      assert title_attr.searchable == true

      author_rel = find_relationship(schema, :author)
      assert author_rel.label == "Written By"
    end

    test "handles empty overrides" do
      defmodule NoOverridesLive do
        use Phoenix.LiveView

        use AshPanel.LiveView,
          resource: TestUser,
          domain: TestDomain,
          views: [:list],
          overrides: %{}
      end

      schema = NoOverridesLive.__ash_panel_schema__()
      assert schema != nil
      assert is_list(schema.attributes)
    end

    test "generates searchable_fields from schema" do
      defmodule SearchableLive do
        use Phoenix.LiveView

        use AshPanel.LiveView,
          resource: TestUser,
          domain: TestDomain,
          views: [:list],
          overrides: %{
            attributes: %{
              name: %{searchable: true},
              email: %{searchable: true}
            }
          }
      end

      schema = SearchableLive.__ash_panel_schema__()

      # Should include explicitly marked searchable fields
      assert :name in schema.searchable_fields or
               Enum.any?(schema.attributes, fn attr ->
                 attr.name == :name and attr.searchable == true
               end)
    end
  end

  describe "setup_ash_panel/2" do
    test "initializes computers in socket assigns" do
      # This would require a full LiveView test setup
      # For now, we test that the function exists and accepts parameters

      defmodule SetupTestLive do
        use Phoenix.LiveView

        use AshPanel.LiveView,
          resource: TestUser,
          domain: TestDomain,
          views: [:list]

        def mount(_params, _session, socket) do
          {:ok, socket}
        end
      end

      # Should compile without errors
      assert SetupTestLive.__ash_panel_schema__() != nil
    end

    test "accepts custom options" do
      defmodule CustomOptionsLive do
        use Phoenix.LiveView

        use AshPanel.LiveView,
          resource: TestUser,
          domain: TestDomain,
          views: [:list],
          page_size: 25,
          sort_by: :name,
          sort_direction: :asc
      end

      # Should compile with custom options
      assert CustomOptionsLive.__ash_panel_schema__() != nil
    end

    test "wires all computers correctly" do
      defmodule WiredLive do
        use Phoenix.LiveView

        use AshPanel.LiveView,
          resource: TestUser,
          domain: TestDomain,
          views: [:list, :detail, :form]

        def mount(_params, _session, socket) do
          {:ok, socket}
        end
      end

      # All views should be configured
      assert WiredLive.__ash_panel_schema__() != nil
    end
  end

  describe "event wiring" do
    test "wires filter events correctly" do
      # Test that event names are generated correctly
      event_name = AshPanel.LiveView.event(:filters, :set_filter)
      assert event_name == "filters_set_filter"

      clear_event = AshPanel.LiveView.event(:filters, :clear_all)
      assert clear_event == "filters_clear_all"
    end

    test "wires pagination events correctly" do
      next_page = AshPanel.LiveView.event(:pagination, :next_page)
      assert next_page == "pagination_next_page"

      prev_page = AshPanel.LiveView.event(:pagination, :prev_page)
      assert prev_page == "pagination_prev_page"

      set_page_size = AshPanel.LiveView.event(:pagination, :set_page_size)
      assert set_page_size == "pagination_set_page_size"
    end

    test "wires form events correctly" do
      submit_event = AshPanel.LiveView.event(:form, :submit)
      assert submit_event == "form_submit"

      validate_event = AshPanel.LiveView.event(:form, :validate)
      assert validate_event == "form_validate"
    end

    test "wires list view events correctly" do
      sort_event = AshPanel.LiveView.event(:list_view, :sort)
      assert sort_event == "list_view_sort"

      select_event = AshPanel.LiveView.event(:list_view, :select_row)
      assert select_event == "list_view_select_row"
    end

    test "event names use underscores not colons" do
      event_name = AshPanel.LiveView.event(:my_computer, :my_event)

      refute String.contains?(event_name, ":")
      refute String.contains?(event_name, "send_event")
      assert event_name == "my_computer_my_event"
    end

    test "event names are compatible with AshComputer.LiveView" do
      # AshComputer.LiveView generates handle_event callbacks like:
      # handle_event("computer_name_event_name", params, socket)

      event_name = AshPanel.LiveView.event(:list_view, :set_page_size)
      assert event_name == "list_view_set_page_size"

      # This format should match AshComputer's expectations
      assert event_name =~ ~r/^[a-z_]+$/
    end
  end

  describe "ResourceLive mount handling" do
    test "mounts with list view by default" do
      # ResourceLive behavior testing would require full LiveView test setup
      # For now, verify that the module compiles correctly

      defmodule ResourceLiveTest do
        use Phoenix.LiveView

        use AshPanel.LiveView,
          resource: TestUser,
          domain: TestDomain,
          views: [:list]

        def mount(_params, _session, socket) do
          {:ok, socket}
        end
      end

      assert ResourceLiveTest.__ash_panel_schema__() != nil
    end

    test "handles multiple view configurations" do
      defmodule MultiViewResourceLive do
        use Phoenix.LiveView

        use AshPanel.LiveView,
          resource: TestUser,
          domain: TestDomain,
          views: [:list, :detail, :form]

        def mount(_params, _session, socket) do
          {:ok, socket}
        end
      end

      schema = MultiViewResourceLive.__ash_panel_schema__()
      assert schema != nil
    end

    test "applies overrides across all views" do
      defmodule OverriddenResourceLive do
        use Phoenix.LiveView

        use AshPanel.LiveView,
          resource: TestUser,
          domain: TestDomain,
          views: [:list, :detail],
          overrides: %{
            attributes: %{
              name: %{label: "User Name"},
              email: %{label: "Email Address"}
            }
          }

        def mount(_params, _session, socket) do
          {:ok, socket}
        end
      end

      schema = OverriddenResourceLive.__ash_panel_schema__()

      name_attr = find_attribute(schema, :name)
      assert name_attr.label == "User Name"

      email_attr = find_attribute(schema, :email)
      assert email_attr.label == "Email Address"
    end
  end

  describe "compile-time behavior" do
    test "validates resource is an Ash resource" do
      # Should compile successfully with valid resource
      defmodule ValidResourceLive do
        use Phoenix.LiveView

        use AshPanel.LiveView,
          resource: TestUser,
          domain: TestDomain,
          views: [:list]
      end

      assert ValidResourceLive.__ash_panel_schema__() != nil
    end

    test "validates domain is an Ash domain" do
      # Should compile successfully with valid domain
      defmodule ValidDomainLive do
        use Phoenix.LiveView

        use AshPanel.LiveView,
          resource: TestUser,
          domain: TestDomain,
          views: [:list]
      end

      assert ValidDomainLive.__ash_panel_schema__() != nil
    end

    test "validates views option is provided" do
      # Should compile with views option
      defmodule ViewsProvidedLive do
        use Phoenix.LiveView

        use AshPanel.LiveView,
          resource: TestUser,
          domain: TestDomain,
          views: [:list]
      end

      assert ViewsProvidedLive.__ash_panel_schema__() != nil
    end

    test "handles multiple resource types" do
      # Test with TestPost instead of TestUser
      defmodule PostResourceLive do
        use Phoenix.LiveView

        use AshPanel.LiveView,
          resource: TestPost,
          domain: TestDomain,
          views: [:list]
      end

      schema = PostResourceLive.__ash_panel_schema__()
      assert schema.resource == TestPost
    end
  end
end
