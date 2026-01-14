defmodule Absinthe.Object.RootMutationTest do
  use ExUnit.Case, async: true

  defmodule TestMutation do
    use Absinthe.Object.RootMutation

    root_mutation_fields do
      field :create_thing, :string do
        resolve fn _, _, _ -> {:ok, "created"} end
      end

      field :delete_thing, :boolean
    end
  end

  describe "RootMutation" do
    test "defines __absinthe_object_kind__" do
      assert TestMutation.__absinthe_object_kind__() == :root_mutation
    end

    test "defines __absinthe_object_definition__" do
      assert TestMutation.__absinthe_object_definition__() == %{kind: :root_mutation}
    end

    test "defines __absinthe_object_mutation_fields_identifier__" do
      assert TestMutation.__absinthe_object_mutation_fields_identifier__() == :absinthe_object_root_mutation_fields
    end
  end
end
