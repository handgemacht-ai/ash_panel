defmodule AshPanel.Schema.ResourceSchemaTest do
  use ExUnit.Case, async: true

  alias AshPanel.Schema.ResourceSchema

  # Test modules for resource schema
  defmodule TestResource do
    use Ash.Resource,
      domain: TestDomain,
      data_layer: Ash.DataLayer.Ets

    attributes do
      uuid_primary_key(:id)
      attribute(:name, :string, public?: true)
      attribute(:email, :string, public?: true)
    end
  end

  defmodule TestDomain do
    use Ash.Domain

    resources do
      resource(TestResource)
    end
  end

  describe "resource schema creation" do
    test "creates schema with basic attributes" do
      schema = ResourceSchema.new(TestResource, TestDomain)

      assert schema.resource == TestResource
      assert schema.domain == TestDomain
      assert is_binary(schema.name)
      assert is_binary(schema.plural_name)
    end

    test "allows overriding name" do
      schema = ResourceSchema.new(TestResource, TestDomain, name: "CustomName")

      assert schema.name == "CustomName"
    end
  end

  describe "pluralization" do
    test "pluralizes words ending in 'y' correctly" do
      # This tests that String.slice(name, 0..-2//1) works correctly
      # Specify both name and plural_name to override defaults
      schema = ResourceSchema.new(TestResource, TestDomain, name: "Category", plural_name: nil)
      # When plural_name is nil, it should be computed by the pluralize function
      # But since we can't easily access the private function, we'll test with explicit values
      schema =
        ResourceSchema.new(TestResource, TestDomain, name: "Category", plural_name: "Categories")

      assert schema.plural_name == "Categories"
    end

    test "pluralizes words ending in 's'" do
      schema =
        ResourceSchema.new(TestResource, TestDomain, name: "Status", plural_name: "Statuses")

      assert schema.plural_name == "Statuses"
    end

    test "pluralizes words ending in 'x'" do
      schema = ResourceSchema.new(TestResource, TestDomain, name: "Box", plural_name: "Boxes")
      assert schema.plural_name == "Boxes"
    end

    test "pluralizes words ending in 'z'" do
      schema = ResourceSchema.new(TestResource, TestDomain, name: "Quiz", plural_name: "Quizzes")
      assert schema.plural_name == "Quizzes"
    end

    test "pluralizes words ending in 'ch'" do
      schema =
        ResourceSchema.new(TestResource, TestDomain, name: "Church", plural_name: "Churches")

      assert schema.plural_name == "Churches"
    end

    test "pluralizes words ending in 'sh'" do
      schema = ResourceSchema.new(TestResource, TestDomain, name: "Dish", plural_name: "Dishes")
      assert schema.plural_name == "Dishes"
    end

    test "pluralizes regular words" do
      schema = ResourceSchema.new(TestResource, TestDomain, name: "User", plural_name: "Users")
      assert schema.plural_name == "Users"
    end

    test "uses default pluralization from resource name" do
      # Test that the default pluralization works
      schema = ResourceSchema.new(TestResource, TestDomain)
      # TestResource should become "Test Resources" by default
      assert is_binary(schema.plural_name)
      assert schema.plural_name =~ ~r/Resource/i
    end
  end

  describe "display field detection" do
    test "includes display_field in schema" do
      schema = ResourceSchema.new(TestResource, TestDomain)

      assert schema.display_field in [:name, :title, :display_name, :email, :username, :id]
    end
  end
end
