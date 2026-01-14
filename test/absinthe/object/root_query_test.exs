defmodule Absinthe.Object.RootQueryTest do
  use ExUnit.Case, async: true

  defmodule TestQuery do
    use Absinthe.Object.RootQuery

    root_query_fields do
      field :health, :string do
        resolve fn _, _, _ -> {:ok, "ok"} end
      end

      field :version, :string
    end
  end

  describe "RootQuery" do
    test "defines __absinthe_object_kind__" do
      assert TestQuery.__absinthe_object_kind__() == :root_query
    end

    test "defines __absinthe_object_definition__" do
      assert TestQuery.__absinthe_object_definition__() == %{kind: :root_query}
    end

    test "defines __absinthe_object_query_fields_identifier__" do
      assert TestQuery.__absinthe_object_query_fields_identifier__() == :absinthe_object_root_query_fields
    end
  end
end
