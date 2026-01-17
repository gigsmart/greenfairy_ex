defmodule SocialNetworkWeb.GraphQL.Queries.RootQuery do
  @moduledoc """
  Root query module demonstrating GreenFairy's query macros.

  ## Query Field Generation

  Query fields are generated from multiple sources:

  1. **Type-side `expose`** - Types with `expose :id` auto-generate query fields
     This is the recommended approach for simple lookups.

  2. **Query-side `list`** - Auto-generates list fields with CQL filtering
     No custom resolver needed - CQL filtering is automatic.

  3. **Query-side `connection`** - Auto-generates paginated connections with CQL

  4. **Custom fields** - For fields requiring custom resolver logic

  ## Example

  In types:

      type "User", struct: User do
        expose :id          # Generates: user(id: ID!): User
      end

  In queries (this module):

      queries do
        node_field()        # Relay Node resolution
        list :users, Types.User   # List with CQL filtering
      end

  """
  use GreenFairy.Query

  alias SocialNetworkWeb.GraphQL.Types

  queries do
    # Relay Node field - automatically decodes GlobalId and fetches the record
    node_field()

    # NOTE: user(id:) and post(id:) are auto-generated from the types
    # because they have `expose :id` defined. No need to define them here!

    # List queries with automatic CQL filtering
    # No resolver needed - the list macro handles everything!
    list :users, Types.User
    list :posts, Types.Post

    # Current viewer - custom field (not exposed via GlobalId)
    field :viewer, Types.User do
      resolve fn _, %{context: context} ->
        {:ok, context[:current_user]}
      end
    end
  end
end
