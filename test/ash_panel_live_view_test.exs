defmodule AshPanel.LiveViewTest do
  use ExUnit.Case, async: false

  defmodule TestUser do
    use Ash.Resource,
      domain: TestDomain,
      data_layer: Ash.DataLayer.Ets

    ets do
      table(:test_users)
    end

    actions do
      defaults([:read, :destroy])
      create(:create)
    end

    attributes do
      uuid_primary_key(:id)
      attribute(:name, :string)
      attribute(:email, :string)
    end
  end

  defmodule TestDomain do
    use Ash.Domain

    resources do
      resource(TestUser)
    end
  end

  describe "AshPanel.LiveView" do
    test "accepts literal overrides map" do
      defmodule OverrideLive do
        use Phoenix.LiveView

        use AshPanel.LiveView,
          resource: TestUser,
          domain: TestDomain,
          views: [:list],
          overrides: %{attributes: %{name: %{label: "Full Name"}}}
      end

      schema = OverrideLive.__ash_panel_schema__()
      name_attr = Enum.find(schema.attributes, &(&1.name == :name))

      assert name_attr.label == "Full Name"
    end
  end

  describe "event/2" do
    test "generates event names compatible with AshComputer.LiveView" do
      # AshComputer.LiveView generates handle_event callbacks like:
      # handle_event("computer_name_event_name", params, socket)

      # AshPanel.LiveView.event/2 should generate the same format
      assert AshPanel.LiveView.event(:list_view, :set_page_size) == "list_view_set_page_size"
      assert AshPanel.LiveView.event(:detail_view, :select_record) == "detail_view_select_record"
      assert AshPanel.LiveView.event(:filters, :set_filter) == "filters_set_filter"
    end

    test "event names use underscores not colons" do
      event_name = AshPanel.LiveView.event(:my_computer, :my_event)

      refute String.contains?(event_name, ":")
      refute String.contains?(event_name, "send_event")
      assert event_name == "my_computer_my_event"
    end
  end
end
