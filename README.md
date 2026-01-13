# Absinthe.Object

A cleaner DSL for GraphQL schema definitions built on [Absinthe](https://github.com/absinthe-graphql/absinthe).

## Overview

Absinthe.Object provides a streamlined way to define GraphQL schemas following SOLID principles:
- **One module = one type** - Each GraphQL type lives in its own file
- **Convention over configuration** - Smart defaults reduce boilerplate
- **Auto-discovery** - Types are automatically discovered and registered
- **Extensible** - Build custom DSL extensions like query languages on top

## Installation

Add `absinthe_object` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:absinthe_object, "~> 0.1.0"}
  ]
end
```

## Quick Start

### Define a Type

```elixir
defmodule MyApp.GraphQL.Types.User do
  use Absinthe.Object.Type

  type "User", struct: MyApp.User do
    implements MyApp.GraphQL.Interfaces.Node

    field :email, :string, null: false
    field :name, :string

    belongs_to :organization, MyApp.GraphQL.Types.Organization
    has_many :posts, MyApp.GraphQL.Types.Post

    connection :friends, MyApp.GraphQL.Types.User do
      edge do
        field :friendship_date, :datetime
      end
    end
  end
end
```

### Define an Interface

```elixir
defmodule MyApp.GraphQL.Interfaces.Node do
  use Absinthe.Object.Interface

  interface "Node" do
    field :id, :id, null: false
    # resolve_type is auto-generated from types that call `implements`!
  end
end
```

### Define the Schema

```elixir
defmodule MyApp.GraphQL.Schema do
  use Absinthe.Object.Schema,
    discover: [MyApp.GraphQL]
end
```

## Documentation

See [PLAN.md](PLAN.md) for the complete implementation plan and DSL reference.

## License

MIT License - see [LICENSE](LICENSE) for details.
