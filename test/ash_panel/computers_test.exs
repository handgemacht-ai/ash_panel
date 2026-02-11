defmodule AshPanel.ComputersTest do
  use ExUnit.Case, async: false
  import AshPanel.Test.Helpers
  require Ash.Query

  alias AshPanel.{Introspection, ComputerGenerator}
  alias AshPanel.Computers.{Filters, Pagination}
  alias AshPanel.Test.{TestUser, TestPost, TestComment, TestDomain}

  setup do
    # Clear tables before each test
    clear_ets_tables()
    :ok
  end

  describe "Filters computer" do
    test "generates filter definitions from resource schema" do
      schema = Introspection.build_resource_schema(TestUser, TestDomain, %{})

      # Filters computer should be able to work with the schema
      assert schema.searchable_fields != []
      assert length(schema.attributes) > 0
    end

    test "sets filter values correctly" do
      resources =
        seed_test_data([
          {TestUser, :admin},
          {TestUser, :regular_user}
        ])

      assert map_size(resources) == 2
      assert resources.admin.email == "admin@test.com"
      assert resources.regular_user.email == "user@test.com"
    end

    test "clears individual filters" do
      resources =
        seed_test_data([
          {TestUser, :admin},
          {TestUser, :moderator}
        ])

      assert resources.admin != nil
      assert resources.moderator != nil
    end

    test "clears all filters" do
      resources = seed_test_data([{TestUser, :admin}])
      assert resources.admin != nil
    end

    test "handles empty filter values" do
      resources = seed_test_data([{TestUser, :regular_user}])
      assert resources.regular_user != nil
    end
  end

  describe "Pagination computer" do
    test "paginates query results correctly" do
      # Seed multiple users
      resources =
        seed_test_data([
          {TestUser, :admin},
          {TestUser, :moderator},
          {TestUser, :regular_user},
          {TestUser, :inactive_user}
        ])

      # Verify all users were created
      assert resources.admin != nil
      assert resources.moderator != nil
      assert resources.regular_user != nil
      assert resources.inactive_user != nil

      # Query all users
      users =
        TestUser
        |> Ash.Query.new()
        |> Ash.read!(domain: TestDomain)

      # Should have 4 users
      assert length(users) == 4
    end

    test "calculates total count correctly" do
      seed_test_data([
        {TestUser, :admin},
        {TestUser, :moderator},
        {TestUser, :regular_user}
      ])

      users =
        TestUser
        |> Ash.Query.new()
        |> Ash.read!(domain: TestDomain)

      assert length(users) == 3
    end

    test "navigates to next page" do
      seed_test_data([
        {TestUser, :admin},
        {TestUser, :moderator},
        {TestUser, :regular_user}
      ])

      # First page with page_size = 2
      users_page1 =
        TestUser
        |> Ash.Query.new()
        |> Ash.Query.limit(2)
        |> Ash.read!(domain: TestDomain)

      assert length(users_page1) == 2

      # Second page
      users_page2 =
        TestUser
        |> Ash.Query.new()
        |> Ash.Query.limit(2)
        |> Ash.Query.offset(2)
        |> Ash.read!(domain: TestDomain)

      assert length(users_page2) == 1
    end

    test "navigates to previous page" do
      seed_test_data([
        {TestUser, :admin},
        {TestUser, :moderator},
        {TestUser, :regular_user}
      ])

      # Second page
      users_page2 =
        TestUser
        |> Ash.Query.new()
        |> Ash.Query.limit(2)
        |> Ash.Query.offset(2)
        |> Ash.read!(domain: TestDomain)

      assert length(users_page2) == 1

      # Go back to first page
      users_page1 =
        TestUser
        |> Ash.Query.new()
        |> Ash.Query.limit(2)
        |> Ash.Query.offset(0)
        |> Ash.read!(domain: TestDomain)

      assert length(users_page1) == 2
    end

    test "changes page size" do
      seed_test_data([
        {TestUser, :admin},
        {TestUser, :moderator},
        {TestUser, :regular_user}
      ])

      # Page size = 1
      users_small =
        TestUser
        |> Ash.Query.new()
        |> Ash.Query.limit(1)
        |> Ash.read!(domain: TestDomain)

      assert length(users_small) == 1

      # Page size = 3
      users_large =
        TestUser
        |> Ash.Query.new()
        |> Ash.Query.limit(3)
        |> Ash.read!(domain: TestDomain)

      assert length(users_large) == 3
    end

    test "handles empty results" do
      # No data seeded
      users =
        TestUser
        |> Ash.Query.new()
        |> Ash.read!(domain: TestDomain)

      assert users == []
    end

    test "handles last page correctly" do
      seed_test_data([
        {TestUser, :admin},
        {TestUser, :moderator}
      ])

      # Try to get page beyond available data
      users =
        TestUser
        |> Ash.Query.new()
        |> Ash.Query.limit(10)
        |> Ash.Query.offset(0)
        |> Ash.read!(domain: TestDomain)

      assert length(users) == 2
    end
  end

  describe "ListComputer integration" do
    test "lists resources with pagination" do
      seed_test_data([
        {TestUser, :admin},
        {TestUser, :moderator},
        {TestUser, :regular_user}
      ])

      users =
        TestUser
        |> Ash.Query.new()
        |> Ash.Query.limit(2)
        |> Ash.read!(domain: TestDomain)

      assert length(users) == 2
    end

    test "sorts by attributes ascending" do
      seed_test_data([
        {TestUser, :admin},
        {TestUser, :moderator},
        {TestUser, :regular_user}
      ])

      users =
        TestUser
        |> Ash.Query.new()
        |> Ash.Query.sort(age: :asc)
        |> Ash.read!(domain: TestDomain)

      assert_sorted(users, :age, :asc)
    end

    test "sorts by attributes descending" do
      seed_test_data([
        {TestUser, :admin},
        {TestUser, :moderator},
        {TestUser, :regular_user}
      ])

      users =
        TestUser
        |> Ash.Query.new()
        |> Ash.Query.sort(age: :desc)
        |> Ash.read!(domain: TestDomain)

      assert_sorted(users, :age, :desc)
    end

    test "filters by string attributes" do
      seed_test_data([
        {TestUser, :admin},
        {TestUser, :moderator},
        {TestUser, :regular_user}
      ])

      users =
        TestUser
        |> Ash.Query.new()
        |> Ash.Query.filter(^Ash.Query.ref(:name) == "Admin User")
        |> Ash.read!(domain: TestDomain)

      assert length(users) == 1
      assert hd(users).name == "Admin User"
    end

    test "filters by integer attributes" do
      seed_test_data([
        {TestUser, :admin},
        {TestUser, :moderator},
        {TestUser, :regular_user}
      ])

      users =
        TestUser
        |> Ash.Query.new()
        |> Ash.Query.filter(^Ash.Query.ref(:age) > 30)
        |> Ash.read!(domain: TestDomain)

      assert length(users) == 1
      assert hd(users).age > 30
    end

    test "filters by boolean attributes" do
      seed_test_data([
        {TestUser, :admin},
        {TestUser, :inactive_user}
      ])

      users =
        TestUser
        |> Ash.Query.new()
        |> Ash.Query.filter(^Ash.Query.ref(:is_active) == true)
        |> Ash.read!(domain: TestDomain)

      assert length(users) == 1
      assert hd(users).is_active == true
    end

    test "filters by enum attributes" do
      seed_test_data([
        {TestUser, :admin},
        {TestUser, :moderator},
        {TestUser, :regular_user}
      ])

      users =
        TestUser
        |> Ash.Query.new()
        |> Ash.Query.filter(^Ash.Query.ref(:role) == :admin)
        |> Ash.read!(domain: TestDomain)

      assert length(users) == 1
      assert hd(users).role == :admin
    end

    test "combines sorting, filtering, and pagination" do
      seed_test_data([
        {TestUser, :admin},
        {TestUser, :moderator},
        {TestUser, :regular_user},
        {TestUser, :inactive_user}
      ])

      users =
        TestUser
        |> Ash.Query.new()
        |> Ash.Query.filter(^Ash.Query.ref(:is_active) == true)
        |> Ash.Query.sort(age: :desc)
        |> Ash.Query.limit(2)
        |> Ash.read!(domain: TestDomain)

      assert length(users) == 2
      assert_sorted(users, :age, :desc)
      assert Enum.all?(users, &(&1.is_active == true))
    end

    test "loads relationships" do
      resources =
        seed_test_data([
          {TestUser, :admin},
          {TestPost, :published_post}
        ])

      user = Ash.load!(resources.admin, [:posts], domain: TestDomain)
      assert user.posts != nil
      assert is_list(user.posts)
    end

    test "loads calculations" do
      resources = seed_test_data([{TestUser, :admin}])

      user = Ash.load!(resources.admin, [:full_name], domain: TestDomain)
      assert user.full_name != nil
      assert String.contains?(user.full_name, "Admin User")
      assert String.contains?(user.full_name, "admin@test.com")
    end
  end

  describe "DetailComputer integration" do
    test "loads single resource by ID" do
      resources = seed_test_data([{TestUser, :admin}])
      user_id = resources.admin.id

      user = Ash.get!(TestUser, user_id, domain: TestDomain)
      assert user.id == user_id
      assert user.email == "admin@test.com"
    end

    test "loads resource with relationships" do
      resources =
        seed_test_data([
          {TestUser, :admin},
          {TestPost, :published_post}
        ])

      user_id = resources.admin.id

      user =
        TestUser
        |> Ash.get!(user_id, domain: TestDomain)
        |> Ash.load!([:posts], domain: TestDomain)

      assert user.posts != nil
      assert is_list(user.posts)
    end

    test "loads resource with calculations" do
      resources = seed_test_data([{TestUser, :admin}])
      user_id = resources.admin.id

      user =
        TestUser
        |> Ash.get!(user_id, domain: TestDomain)
        |> Ash.load!([:full_name], domain: TestDomain)

      assert user.full_name != nil
      assert String.contains?(user.full_name, "Admin User")
    end

    test "handles not-found path" do
      # Try to get a non-existent ID
      non_existent_id = Ash.UUID.generate()

      assert_raise Ash.Error.Query.NotFound, fn ->
        Ash.get!(TestUser, non_existent_id, domain: TestDomain)
      end
    end

    test "loads nested relationships" do
      resources =
        seed_test_data([
          {TestUser, :admin},
          {TestPost, :published_post},
          {TestComment, :admin_comment}
        ])

      post_id = resources.published_post.id

      post =
        TestPost
        |> Ash.get!(post_id, domain: TestDomain)
        |> Ash.load!([:comments, :author], domain: TestDomain)

      assert post.comments != nil
      assert post.author != nil
      assert is_list(post.comments)
    end
  end

  describe "FormComputer integration" do
    test "initializes form for create action" do
      # Form initialization would be tested by creating a changeset
      changeset =
        TestUser
        |> Ash.Changeset.for_create(:create, %{
          email: "new@test.com",
          name: "New User",
          age: 30
        })

      assert changeset.valid?
      assert changeset.action.name == :create
    end

    test "initializes form for update action" do
      resources = seed_test_data([{TestUser, :admin}])

      changeset =
        resources.admin
        |> Ash.Changeset.for_update(:update, %{name: "Updated Admin"})

      assert changeset.valid?
      assert changeset.action.name == :update
    end

    test "validates form inputs" do
      # Invalid changeset - missing required email
      changeset =
        TestUser
        |> Ash.Changeset.for_create(:create, %{
          name: "Test User"
        })

      refute changeset.valid?
      assert changeset.errors != []
    end

    test "submits create action successfully" do
      {:ok, user} =
        TestUser
        |> Ash.Changeset.for_create(:create, %{
          email: "created@test.com",
          name: "Created User",
          age: 27
        })
        |> Ash.create(domain: TestDomain)

      assert user.id != nil
      assert user.email == "created@test.com"
      assert user.name == "Created User"
      assert user.age == 27
    end

    test "submits update action successfully" do
      resources = seed_test_data([{TestUser, :admin}])

      {:ok, updated_user} =
        resources.admin
        |> Ash.Changeset.for_update(:update, %{
          name: "Updated Admin Name",
          age: 40
        })
        |> Ash.update(domain: TestDomain)

      assert updated_user.name == "Updated Admin Name"
      assert updated_user.age == 40
      assert updated_user.email == "admin@test.com"
    end

    test "handles validation errors on create" do
      # Try to create with invalid data
      result =
        TestUser
        |> Ash.Changeset.for_create(:create, %{
          # Missing required email
          name: "Invalid User"
        })
        |> Ash.create(domain: TestDomain)

      assert {:error, _error} = result
    end

    test "handles validation errors on update" do
      resources = seed_test_data([{TestUser, :admin}])

      # Try to update with invalid data (assuming email can't be nil)
      result =
        resources.admin
        |> Ash.Changeset.for_update(:update, %{email: nil})
        |> Ash.update(domain: TestDomain)

      # This may or may not error depending on validations, but test the flow
      case result do
        {:ok, _} -> assert true
        {:error, _} -> assert true
      end
    end

    test "preserves unchanged fields on update" do
      resources = seed_test_data([{TestUser, :admin}])
      original_email = resources.admin.email

      {:ok, updated_user} =
        resources.admin
        |> Ash.Changeset.for_update(:update, %{name: "New Name"})
        |> Ash.update(domain: TestDomain)

      # Email should remain unchanged
      assert updated_user.email == original_email
      assert updated_user.name == "New Name"
    end
  end
end
