defmodule AshPanel.Test.TestDomain do
  @moduledoc """
  Test domain for ash_panel tests
  """
  use Ash.Domain

  resources do
    resource(AshPanel.Test.TestUser)
    resource(AshPanel.Test.TestPost)
    resource(AshPanel.Test.TestComment)
  end
end
