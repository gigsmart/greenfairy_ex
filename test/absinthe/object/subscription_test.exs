defmodule Absinthe.Object.SubscriptionTest do
  use ExUnit.Case, async: true

  defmodule TestSubscriptions do
    use Absinthe.Object.Subscription

    subscriptions do
      field :item_created, :string do
        config fn _, _ -> {:ok, topic: "items"} end
      end

      field :item_updated, :string do
        arg :id, :id

        config fn args, _ ->
          topic = args[:id] || "all"
          {:ok, topic: topic}
        end
      end
    end
  end

  describe "Subscription module" do
    test "defines __absinthe_object_kind__" do
      assert TestSubscriptions.__absinthe_object_kind__() == :subscriptions
    end

    test "defines __absinthe_object_definition__" do
      definition = TestSubscriptions.__absinthe_object_definition__()

      assert definition.kind == :subscriptions
      assert definition.has_subscriptions == true
    end

    test "stores subscription fields block" do
      assert function_exported?(TestSubscriptions, :__absinthe_object_subscription_fields__, 0)
    end
  end

  describe "Subscription module without subscriptions block" do
    defmodule EmptySubscriptions do
      use Absinthe.Object.Subscription
    end

    test "has has_subscriptions as false" do
      definition = EmptySubscriptions.__absinthe_object_definition__()
      assert definition.has_subscriptions == false
    end
  end

  describe "Subscription integration with schema" do
    defmodule SubscriptionSchema do
      use Absinthe.Schema

      import_types TestSubscriptions

      query do
        field :dummy, :string do
          resolve fn _, _, _ -> {:ok, "dummy"} end
        end
      end

      subscription do
        import_fields :absinthe_object_subscriptions
      end
    end

    test "schema has subscription fields" do
      type = Absinthe.Schema.lookup_type(SubscriptionSchema, :subscription)

      assert type != nil
      assert Map.has_key?(type.fields, :item_created)
      assert Map.has_key?(type.fields, :item_updated)
    end
  end
end
