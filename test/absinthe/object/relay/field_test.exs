defmodule Absinthe.Object.Relay.FieldTest do
  use ExUnit.Case, async: true

  alias Absinthe.Object.Relay.Field

  describe "get_type_name/2" do
    defmodule TypeWithTypeName do
      def __absinthe_object_type_name__, do: "CustomTypeName"
    end

    defmodule TypeWithoutTypeName do
      # No __absinthe_object_type_name__ function
    end

    test "returns type name from module when available" do
      assert "CustomTypeName" = Field.get_type_name(TypeWithTypeName, nil)
    end

    test "falls back to module name when no type name function" do
      result = Field.get_type_name(TypeWithoutTypeName, nil)
      assert result == "TypeWithoutTypeName"
    end

    test "uses resolution definition when available" do
      resolution = %{
        definition: %{
          schema_node: %{
            identifier: :my_type
          }
        }
      }

      result = Field.get_type_name(TypeWithoutTypeName, resolution)
      assert result == "MyType"
    end
  end
end
