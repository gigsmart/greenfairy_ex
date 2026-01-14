# Relationships and DataLoader

This guide covers how to define relationships between types and use DataLoader for efficient batching.

## Relationship Macros

Absinthe.Object provides three relationship macros that automatically generate DataLoader resolvers:

### has_many

Use `has_many` for one-to-many relationships:

```elixir
defmodule MyApp.GraphQL.Types.User do
  use Absinthe.Object.Type

  type "User", struct: MyApp.User do
    field :id, non_null(:id)
    field :name, :string

    # A user has many posts
    has_many :posts, MyApp.GraphQL.Types.Post
  end
end
```

### has_one

Use `has_one` for one-to-one relationships:

```elixir
defmodule MyApp.GraphQL.Types.User do
  use Absinthe.Object.Type

  type "User", struct: MyApp.User do
    field :id, non_null(:id)

    # A user has one profile
    has_one :profile, MyApp.GraphQL.Types.Profile
  end
end
```

### belongs_to

Use `belongs_to` for the inverse side of relationships:

```elixir
defmodule MyApp.GraphQL.Types.Post do
  use Absinthe.Object.Type

  type "Post", struct: MyApp.Post do
    field :id, non_null(:id)
    field :title, :string

    # A post belongs to a user (author)
    belongs_to :author, MyApp.GraphQL.Types.User
  end
end
```

## DataLoader Setup

To use relationships, you need to configure DataLoader in your schema:

### 1. Create a DataLoader Source

```elixir
defmodule MyApp.DataLoader do
  def data do
    Dataloader.Ecto.new(MyApp.Repo, query: &query/2)
  end

  def query(queryable, _params) do
    queryable
  end
end
```

### 2. Configure Your Schema

```elixir
defmodule MyApp.GraphQL.Schema do
  use Absinthe.Schema

  # ... import_types ...

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(:repo, MyApp.DataLoader.data())

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader | Absinthe.Plugin.defaults()]
  end
end
```

## Relationship Options

All relationship macros accept options:

```elixir
has_many :posts, MyApp.GraphQL.Types.Post,
  source: :blog,           # DataLoader source name
  args: %{published: true} # Additional args passed to loader
```

## Custom Resolvers

If you need custom logic, you can still use a regular field with a resolver:

```elixir
type "User", struct: MyApp.User do
  field :recent_posts, list_of(:post) do
    resolve fn user, _, %{context: %{loader: loader}} ->
      loader
      |> Dataloader.load(:repo, {:posts, %{limit: 5}}, user)
      |> on_load(fn loader ->
        posts = Dataloader.get(loader, :repo, {:posts, %{limit: 5}}, user)
        {:ok, posts}
      end)
    end
  end
end
```

## N+1 Query Prevention

DataLoader automatically batches queries. For example, if you query:

```graphql
{
  users {
    id
    posts {
      title
    }
  }
}
```

DataLoader will:
1. Load all users in one query
2. Batch all post queries into a single query using `WHERE user_id IN (...)`

This prevents the N+1 query problem common in GraphQL APIs.
