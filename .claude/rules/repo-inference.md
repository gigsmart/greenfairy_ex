# Repo Inference Rule - NEVER FORGET

## Repos are NEVER globally configured

**NEVER add `config :green_fairy, repo: SomeRepo` or any global repo configuration!**

Repos/database connections are ALWAYS inferred from the type's struct adapter, never configured globally.

## How Repo Detection Works

1. **From context**: `context[:repo]` or `context[:current_repo]` (set by the application)
2. **From struct**: `GreenFairy.Adapters.Ecto.get_repo_for_schema(struct_module)` which:
   - Checks if the module defines `__repo__/0`
   - Infers from module name (e.g., `MyApp.Accounts.User` -> `MyApp.Repo`)

## Why This Matters

- GreenFairy supports **multiple databases** in the same GraphQL schema
- Different types can use different repos (Postgres, ClickHouse, Elasticsearch)
- Each type's struct determines which repo/adapter to use
- Global config would break multi-database support

## Correct Pattern

```elixir
# In resolvers (like the list macro):
repo =
  Map.get(ctx, :repo) ||
    Map.get(ctx, :current_repo) ||
    GreenFairy.Adapters.Ecto.get_repo_for_schema(struct_module)
```

## Wrong Pattern

```elixir
# NEVER DO THIS:
config :green_fairy, repo: MyApp.Repo

# NEVER DO THIS:
repo = Application.get_env(:green_fairy, :repo)
```
