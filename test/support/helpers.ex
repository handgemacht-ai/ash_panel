defmodule AshPanel.Test.Helpers do
  @moduledoc """
  Test helpers for ash_panel tests
  """
  import ExUnit.Assertions

  @doc """
  Asserts that a schema has the expected metadata properties
  """
  def assert_schema_metadata(schema, expected) do
    if expected[:primary_keys] do
      assert schema.primary_keys == expected[:primary_keys],
             "Expected primary_keys to be #{inspect(expected[:primary_keys])}, got #{inspect(schema.primary_keys)}"
    end

    if expected[:searchable_fields] do
      assert schema.searchable_fields == expected[:searchable_fields],
             "Expected searchable_fields to be #{inspect(expected[:searchable_fields])}, got #{inspect(schema.searchable_fields)}"
    end

    if expected[:attribute_count] do
      assert length(schema.attributes) == expected[:attribute_count],
             "Expected #{expected[:attribute_count]} attributes, got #{length(schema.attributes)}"
    end

    if expected[:relationship_count] do
      assert length(schema.relationships) == expected[:relationship_count],
             "Expected #{expected[:relationship_count]} relationships, got #{length(schema.relationships)}"
    end

    if expected[:action_count] do
      assert length(schema.actions) == expected[:action_count],
             "Expected #{expected[:action_count]} actions, got #{length(schema.actions)}"
    end
  end

  @doc """
  Asserts that an override was correctly applied to an attribute
  """
  def assert_override_applied(schema, attribute_name, override_key, expected_value) do
    attribute = Enum.find(schema.attributes, &(&1.name == attribute_name))

    assert attribute != nil,
           "Attribute #{attribute_name} not found in schema"

    actual_value = Map.get(attribute, override_key)

    assert actual_value == expected_value,
           "Expected #{attribute_name}.#{override_key} to be #{inspect(expected_value)}, got #{inspect(actual_value)}"
  end

  @doc """
  Finds an attribute in a schema by name
  """
  def find_attribute(schema, name) do
    Enum.find(schema.attributes, &(&1.name == name))
  end

  @doc """
  Finds a relationship in a schema by name
  """
  def find_relationship(schema, name) do
    Enum.find(schema.relationships, &(&1.name == name))
  end

  @doc """
  Finds an action in a schema by name
  """
  def find_action(schema, name) do
    Enum.find(schema.actions, &(&1.name == name))
  end

  @doc """
  Finds a column definition in a list by name
  """
  def find_column(columns, name) do
    Enum.find(columns, &(&1.name == name))
  end

  @doc """
  Creates a test LiveView module that uses AshPanel.LiveView
  """
  defmacro define_test_live_view(module_name, opts) do
    quote do
      defmodule unquote(module_name) do
        use Phoenix.LiveView
        use AshPanel.LiveView, unquote(opts)
      end
    end
  end

  @doc """
  Seeds test data using ash_scenario and returns the resources
  """
  def seed_test_data(prototype_refs, opts \\ []) do
    # Clear ETS tables before seeding
    clear_ets_tables()

    # Run scenarios with database strategy by default
    opts = Keyword.put_new(opts, :strategy, :database)
    opts = Keyword.put_new(opts, :domain, AshPanel.Test.TestDomain)

    case AshScenario.run(prototype_refs, opts) do
      {:ok, resources} -> resources
      {:error, error} -> raise "Failed to seed test data: #{inspect(error)}"
    end
  end

  @doc """
  Clears all ETS tables used by test resources
  """
  def clear_ets_tables do
    :ets.delete_all_objects(:test_users)
    :ets.delete_all_objects(:test_posts)
    :ets.delete_all_objects(:test_comments)
  rescue
    ArgumentError -> :ok
  end

  @doc """
  Asserts that a list of results is sorted by the given field in the given direction
  """
  def assert_sorted(results, field, direction \\ :asc) do
    values = Enum.map(results, &Map.get(&1, field))

    sorted_values =
      case direction do
        :asc -> Enum.sort(values)
        :desc -> Enum.sort(values, :desc)
      end

    assert values == sorted_values,
           "Expected results to be sorted #{direction} by #{field}, got #{inspect(values)}"
  end

  @doc """
  Asserts that all results match the given filter
  """
  def assert_filtered(results, field, operator, value) do
    case operator do
      :eq ->
        Enum.each(results, fn result ->
          assert Map.get(result, field) == value,
                 "Expected #{field} to equal #{inspect(value)}, got #{inspect(Map.get(result, field))}"
        end)

      :contains ->
        Enum.each(results, fn result ->
          field_value = Map.get(result, field) || ""

          assert String.contains?(field_value, value),
                 "Expected #{field} to contain #{inspect(value)}, got #{inspect(field_value)}"
        end)

      :gt ->
        Enum.each(results, fn result ->
          assert Map.get(result, field) > value,
                 "Expected #{field} to be > #{inspect(value)}, got #{inspect(Map.get(result, field))}"
        end)

      :lt ->
        Enum.each(results, fn result ->
          assert Map.get(result, field) < value,
                 "Expected #{field} to be < #{inspect(value)}, got #{inspect(Map.get(result, field))}"
        end)
    end
  end
end
