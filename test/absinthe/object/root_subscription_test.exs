defmodule Absinthe.Object.RootSubscriptionTest do
  use ExUnit.Case, async: true

  defmodule TestSubscription do
    use Absinthe.Object.RootSubscription

    root_subscription_fields do
      field :thing_created, :string do
        config fn _, _ -> {:ok, topic: "things"} end
      end

      field :thing_updated, :string
    end
  end

  describe "RootSubscription" do
    test "defines __absinthe_object_kind__" do
      assert TestSubscription.__absinthe_object_kind__() == :root_subscription
    end

    test "defines __absinthe_object_definition__" do
      assert TestSubscription.__absinthe_object_definition__() == %{kind: :root_subscription}
    end

    test "defines __absinthe_object_subscription_fields_identifier__" do
      assert TestSubscription.__absinthe_object_subscription_fields_identifier__() ==
               :absinthe_object_root_subscription_fields
    end
  end
end
