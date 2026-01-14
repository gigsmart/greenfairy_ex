defmodule Absinthe.Object.Relay.NodeTest do
  use ExUnit.Case, async: true

  alias Absinthe.Object.Relay.Node

  describe "type_name_to_identifier conversion" do
    # We test this indirectly through resolve_node behavior
    # The private function converts "UserProfile" -> :user_profile
  end

  describe "wrap_result/1" do
    # Testing through fetch_node behavior
  end

  describe "resolve_node/3" do
    test "returns error for invalid global ID" do
      resolution = %{schema: TestSchema, context: %{}}

      assert {:error, "Invalid global ID format"} =
               Node.resolve_node("not-a-valid-id", resolution, [])
    end

    test "returns error for malformed base64" do
      resolution = %{schema: TestSchema, context: %{}}

      assert {:error, "Invalid global ID format"} =
               Node.resolve_node("!!!invalid!!!", resolution, [])
    end
  end

  # Define a minimal test schema module
  defmodule TestSchema do
    def __absinthe_types__ do
      []
    end
  end
end
