defmodule Absinthe.Object do
  @moduledoc """
  A cleaner DSL for GraphQL schema definitions built on Absinthe.

  ## Overview

  Absinthe.Object provides a streamlined way to define GraphQL schemas
  following SOLID principles - one module per type, with automatic
  type discovery and smart defaults.

  ## Quick Start

      defmodule MyApp.GraphQL.Types.User do
        use Absinthe.Object.Type

        type "User", struct: MyApp.User do
          implements MyApp.GraphQL.Interfaces.Node

          field :email, :string, null: false
          field :name, :string

          has_many :posts, MyApp.GraphQL.Types.Post
        end
      end

  ## Features

  - One module = one type (SOLID principles)
  - Auto-discovery of types under configured namespaces
  - Smart defaults (Map.get for fields, DataLoader for relationships)
  - Auto-generated `resolve_type` from `implements` + struct mapping
  - Relay-style connections with custom edge fields
  - Native field authorization
  - Macro extensibility for custom DSL extensions
  """
end
