defmodule AshPanel.IntrospectionTest do
  use ExUnit.Case, async: true
  import AshPanel.Test.Helpers

  alias AshPanel.Introspection
  alias AshPanel.Introspection.FilterDefinitionBuilder
  alias AshPanel.Test.{TestUser, TestPost, TestComment, TestDomain}

  describe "build_resource_schema/3" do
    test "generates schema with correct attributes" do
      schema = Introspection.build_resource_schema(TestUser, TestDomain, %{})

      assert_schema_metadata(schema, attribute_count: 9)

      # Check primary key
      assert schema.primary_keys == [:id]

      # Check specific attributes exist
      assert find_attribute(schema, :email) != nil
      assert find_attribute(schema, :name) != nil
      assert find_attribute(schema, :age) != nil
      assert find_attribute(schema, :role) != nil
      assert find_attribute(schema, :is_active) != nil
    end

    test "generates schema with relationships" do
      schema = Introspection.build_resource_schema(TestUser, TestDomain, %{})

      # TestUser has 2 relationships: posts and comments
      assert_schema_metadata(schema, relationship_count: 2)

      posts_rel = find_relationship(schema, :posts)
      assert posts_rel != nil
      assert posts_rel.type == :has_many

      comments_rel = find_relationship(schema, :comments)
      assert comments_rel != nil
      assert comments_rel.type == :has_many
    end

    test "generates schema with actions" do
      schema = Introspection.build_resource_schema(TestUser, TestDomain, %{})

      # TestUser has create, read, update, destroy actions
      assert length(schema.actions) >= 4

      create_action = find_action(schema, :create)
      assert create_action != nil
      assert create_action.type == :create

      read_action = find_action(schema, :read)
      assert read_action != nil
      assert read_action.type == :read
    end

    test "applies attribute overrides" do
      overrides = %{
        attributes: %{
          name: %{
            label: "Full Name",
            hidden: false,
            searchable: true
          },
          email: %{
            label: "Email Address"
          }
        }
      }

      schema = Introspection.build_resource_schema(TestUser, TestDomain, overrides)

      assert_override_applied(schema, :name, :label, "Full Name")
      assert_override_applied(schema, :name, :searchable, true)
      assert_override_applied(schema, :email, :label, "Email Address")
    end

    test "applies relationship overrides" do
      overrides = %{
        relationships: %{
          posts: %{
            label: "User Posts",
            hidden: false
          }
        }
      }

      schema = Introspection.build_resource_schema(TestUser, TestDomain, overrides)

      posts_rel = find_relationship(schema, :posts)
      assert posts_rel.label == "User Posts"
      assert posts_rel.hidden == false
    end

    test "applies action overrides" do
      overrides = %{
        actions: %{
          create: %{
            label: "Create New User"
          }
        }
      }

      schema = Introspection.build_resource_schema(TestUser, TestDomain, overrides)

      create_action = find_action(schema, :create)
      assert create_action.label == "Create New User"
    end

    test "identifies searchable fields" do
      schema = Introspection.build_resource_schema(TestUser, TestDomain, %{})

      # Searchable fields should include string attributes by default
      assert :name in schema.searchable_fields
      assert :email in schema.searchable_fields
    end

    test "includes calculations in schema" do
      schema = Introspection.build_resource_schema(TestUser, TestDomain, %{})

      # TestUser has full_name and post_count calculations
      full_name_calc = Enum.find(schema.attributes, &(&1.name == :full_name))
      assert full_name_calc != nil
      assert full_name_calc.type == :calculation

      post_count_calc = Enum.find(schema.attributes, &(&1.name == :post_count))
      assert post_count_calc != nil
      assert post_count_calc.type == :calculation
    end
  end

  describe "infer_columns/1" do
    test "infers columns from attributes with correct types" do
      schema = Introspection.build_resource_schema(TestUser, TestDomain, %{})
      columns = Introspection.infer_columns(schema)

      # Should have columns for all non-hidden attributes
      assert length(columns) > 0

      name_col = find_column(columns, :name)
      assert name_col != nil
      assert name_col.type == :string

      age_col = find_column(columns, :age)
      assert age_col != nil
      assert age_col.type == :integer

      is_active_col = find_column(columns, :is_active)
      assert is_active_col != nil
      assert is_active_col.type == :boolean
    end

    test "handles various attribute types correctly" do
      schema = Introspection.build_resource_schema(TestUser, TestDomain, %{})
      columns = Introspection.infer_columns(schema)

      # String type
      email_col = find_column(columns, :email)
      assert email_col != nil
      assert email_col.type == :string

      # Integer type
      age_col = find_column(columns, :age)
      assert age_col != nil
      assert age_col.type == :integer

      # Boolean type
      is_active_col = find_column(columns, :is_active)
      assert is_active_col != nil
      assert is_active_col.type == :boolean

      # Atom/enum type
      role_col = find_column(columns, :role)
      assert role_col != nil
      assert role_col.type == :atom

      # Date type
      birthday_col = find_column(columns, :birthday)
      assert birthday_col != nil
      assert birthday_col.type == :date
    end

    test "respects hidden attributes" do
      overrides = %{
        attributes: %{
          bio: %{hidden: true}
        }
      }

      schema = Introspection.build_resource_schema(TestUser, TestDomain, overrides)
      columns = Introspection.infer_columns(schema)

      # Bio should not be in columns if hidden
      bio_col = find_column(columns, :bio)
      assert bio_col == nil
    end

    test "includes calculations as columns" do
      schema = Introspection.build_resource_schema(TestUser, TestDomain, %{})
      columns = Introspection.infer_columns(schema)

      # Calculations should be included in columns
      full_name_col = find_column(columns, :full_name)
      assert full_name_col != nil
      assert full_name_col.type == :string
    end

    test "applies column overrides from schema" do
      overrides = %{
        attributes: %{
          name: %{
            label: "Full Name",
            sortable: false
          }
        }
      }

      schema = Introspection.build_resource_schema(TestUser, TestDomain, overrides)
      columns = Introspection.infer_columns(schema)

      name_col = find_column(columns, :name)
      assert name_col != nil
      assert name_col.label == "Full Name"
      assert name_col.sortable == false
    end
  end

  describe "FilterDefinitionBuilder" do
    test "generates filter definitions from resource" do
      {:ok, filter_defs} = FilterDefinitionBuilder.from_resource(TestUser, %{})

      # Should generate filters for filterable attributes
      assert length(filter_defs) > 0

      # String attributes should have contains filter
      name_filter = Enum.find(filter_defs, &(&1.field == :name))
      assert name_filter != nil
      assert name_filter.type in [:string, :text]

      # Integer attributes should have numeric filters
      age_filter = Enum.find(filter_defs, &(&1.field == :age))
      assert age_filter != nil
      assert age_filter.type == :integer

      # Boolean attributes should have boolean filter
      is_active_filter = Enum.find(filter_defs, &(&1.field == :is_active))
      assert is_active_filter != nil
      assert is_active_filter.type == :boolean
    end

    test "infers correct filter types for each attribute type" do
      {:ok, filter_defs} = FilterDefinitionBuilder.from_resource(TestUser, %{})

      # String type filters
      email_filter = Enum.find(filter_defs, &(&1.field == :email))
      assert email_filter != nil
      assert email_filter.type in [:string, :text]

      # Integer type filters
      age_filter = Enum.find(filter_defs, &(&1.field == :age))
      assert age_filter != nil
      assert age_filter.type == :integer

      # Boolean type filters
      is_active_filter = Enum.find(filter_defs, &(&1.field == :is_active))
      assert is_active_filter != nil
      assert is_active_filter.type == :boolean

      # Atom/enum type filters
      role_filter = Enum.find(filter_defs, &(&1.field == :role))
      assert role_filter != nil
      assert role_filter.type in [:atom, :select]

      # Date type filters
      birthday_filter = Enum.find(filter_defs, &(&1.field == :birthday))
      assert birthday_filter != nil
      assert birthday_filter.type == :date
    end

    test "converts filter values to Ash filter specs" do
      {:ok, filter_defs} = FilterDefinitionBuilder.from_resource(TestUser, %{})

      # Test string filter conversion
      filter_values = %{name: "John"}
      ash_filters = FilterDefinitionBuilder.to_ash_filters(filter_values, filter_defs)
      assert ash_filters != nil
      assert is_list(ash_filters) or is_map(ash_filters)

      # Test integer filter conversion
      filter_values = %{age: 25}
      ash_filters = FilterDefinitionBuilder.to_ash_filters(filter_values, filter_defs)
      assert ash_filters != nil

      # Test boolean filter conversion
      filter_values = %{is_active: true}
      ash_filters = FilterDefinitionBuilder.to_ash_filters(filter_values, filter_defs)
      assert ash_filters != nil
    end

    test "handles empty filter values" do
      {:ok, filter_defs} = FilterDefinitionBuilder.from_resource(TestUser, %{})

      filter_values = %{}
      ash_filters = FilterDefinitionBuilder.to_ash_filters(filter_values, filter_defs)

      # Empty filters should return empty or default filter spec
      assert ash_filters == %{} or ash_filters == []
    end

    test "handles nil and blank filter values" do
      {:ok, filter_defs} = FilterDefinitionBuilder.from_resource(TestUser, %{})

      # Nil values should be filtered out
      filter_values = %{name: nil, age: ""}
      ash_filters = FilterDefinitionBuilder.to_ash_filters(filter_values, filter_defs)

      # Should not include nil or empty string filters
      assert ash_filters == %{} or ash_filters == [] or
               (is_map(ash_filters) and map_size(ash_filters) == 0)
    end
  end
end
