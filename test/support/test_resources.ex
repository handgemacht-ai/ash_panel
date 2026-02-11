defmodule AshPanel.Test.TestUser do
  @moduledoc """
  Test resource with various attribute types and calculations
  """
  use Ash.Resource,
    domain: AshPanel.Test.TestDomain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshScenario.Dsl]

  ets do
    table(:test_users)
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([:email, :name, :age, :role, :is_active, :bio, :birthday])
    end

    update :update do
      accept([:email, :name, :age, :role, :is_active, :bio, :birthday])
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute :email, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :name, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :age, :integer do
      public?(true)
    end

    attribute :role, :atom do
      constraints(one_of: [:admin, :moderator, :user])
      default(:user)
      public?(true)
    end

    attribute :is_active, :boolean do
      default(true)
      public?(true)
    end

    attribute :bio, :string do
      public?(true)
    end

    attribute :birthday, :date do
      public?(true)
    end

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  relationships do
    has_many :posts, AshPanel.Test.TestPost do
      destination_attribute(:author_id)
    end

    has_many :comments, AshPanel.Test.TestComment do
      destination_attribute(:author_id)
    end
  end

  calculations do
    calculate(:full_name, :string, expr(name <> " (" <> email <> ")"))

    calculate :post_count, :integer do
      calculation(fn records, _context ->
        Enum.map(records, fn record ->
          record
          |> Ash.load!(:posts)
          |> Map.get(:posts, [])
          |> length()
        end)
      end)
    end
  end

  prototypes do
    prototype :admin do
      attr(:email, "admin@test.com")
      attr(:name, "Admin User")
      attr(:age, 35)
      attr(:role, :admin)
      attr(:is_active, true)
    end

    prototype :moderator do
      attr(:email, "moderator@test.com")
      attr(:name, "Mod User")
      attr(:age, 28)
      attr(:role, :moderator)
      attr(:is_active, true)
    end

    prototype :regular_user do
      attr(:email, "user@test.com")
      attr(:name, "Regular User")
      attr(:age, 25)
      attr(:role, :user)
      attr(:is_active, true)
    end

    prototype :inactive_user do
      attr(:email, "inactive@test.com")
      attr(:name, "Inactive User")
      attr(:age, 40)
      attr(:role, :user)
      attr(:is_active, false)
    end
  end
end

defmodule AshPanel.Test.TestPost do
  @moduledoc """
  Test resource for testing relationships and filters
  """
  use Ash.Resource,
    domain: AshPanel.Test.TestDomain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshScenario.Dsl]

  ets do
    table(:test_posts)
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([:title, :body, :published, :author_id, :published_at])
    end

    update :update do
      accept([:title, :body, :published, :author_id, :published_at])
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute :title, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :body, :string do
      public?(true)
    end

    attribute :published, :boolean do
      default(false)
      public?(true)
    end

    attribute :published_at, :datetime do
      public?(true)
    end

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  relationships do
    belongs_to :author, AshPanel.Test.TestUser do
      attribute_writable?(true)
    end

    has_many :comments, AshPanel.Test.TestComment do
      destination_attribute(:post_id)
    end
  end

  calculations do
    calculate :comment_count, :integer do
      calculation(fn records, _context ->
        Enum.map(records, fn record ->
          record
          |> Ash.load!(:comments)
          |> Map.get(:comments, [])
          |> length()
        end)
      end)
    end
  end

  prototypes do
    prototype :published_post do
      attr(:title, "Published Post")
      attr(:body, "This is a published post")
      attr(:published, true)
      attr(:author_id, :admin)
    end

    prototype :draft_post do
      attr(:title, "Draft Post")
      attr(:body, "This is a draft post")
      attr(:published, false)
      attr(:author_id, :admin)
    end
  end
end

defmodule AshPanel.Test.TestComment do
  @moduledoc """
  Test resource for nested relationships
  """
  use Ash.Resource,
    domain: AshPanel.Test.TestDomain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshScenario.Dsl]

  ets do
    table(:test_comments)
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([:body, :post_id, :author_id])
    end

    update :update do
      accept([:body, :post_id, :author_id])
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute :body, :string do
      allow_nil?(false)
      public?(true)
    end

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  relationships do
    belongs_to :post, AshPanel.Test.TestPost do
      attribute_writable?(true)
    end

    belongs_to :author, AshPanel.Test.TestUser do
      attribute_writable?(true)
    end
  end

  prototypes do
    prototype :user_comment do
      attr(:body, "Great post!")
      attr(:post_id, :published_post)
      attr(:author_id, :regular_user)
    end

    prototype :admin_comment do
      attr(:body, "Admin feedback")
      attr(:post_id, :published_post)
      attr(:author_id, :admin)
    end
  end
end
