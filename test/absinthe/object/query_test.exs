defmodule Absinthe.Object.QueryTest do
  use ExUnit.Case, async: true

  defmodule TestQueries do
    use Absinthe.Object.Query

    queries do
      field :hello, :string do
        resolve fn _, _, _ -> {:ok, "world"} end
      end

      field :echo, :string do
        arg :message, non_null(:string)
        resolve fn _, %{message: msg}, _ -> {:ok, msg} end
      end
    end
  end

  describe "Query module" do
    test "defines __absinthe_object_kind__" do
      assert TestQueries.__absinthe_object_kind__() == :queries
    end

    test "defines __absinthe_object_definition__" do
      definition = TestQueries.__absinthe_object_definition__()

      assert definition.kind == :queries
      assert definition.has_queries == true
    end

    test "stores query fields block" do
      assert function_exported?(TestQueries, :__absinthe_object_query_fields__, 0)
    end
  end

  describe "Query module without queries block" do
    defmodule EmptyQueries do
      use Absinthe.Object.Query
    end

    test "has has_queries as false" do
      definition = EmptyQueries.__absinthe_object_definition__()
      assert definition.has_queries == false
    end
  end

  describe "Query integration with schema" do
    defmodule QuerySchema do
      use Absinthe.Schema

      import_types TestQueries

      query do
        import_fields :absinthe_object_queries
      end
    end

    test "queries can be executed" do
      assert {:ok, %{data: %{"hello" => "world"}}} =
               Absinthe.run("{ hello }", QuerySchema)
    end

    test "queries with args work" do
      assert {:ok, %{data: %{"echo" => "test"}}} =
               Absinthe.run(~s|{ echo(message: "test") }|, QuerySchema)
    end
  end
end
