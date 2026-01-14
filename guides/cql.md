# CQL (Filterable Queries)

CQL (Composite Query Language) is an extension that automatically generates filter inputs for your GraphQL types based on their backing Ecto schemas.

## Overview

Instead of manually defining filter input types and writing filter logic, CQL:

- Detects your Ecto schema fields and their types
- Generates appropriate operators for each field type
- Creates a `TypeFilter` input automatically
- Integrates with your authorization rules

## Basic Usage

Enable CQL on a type by using the extension:

```elixir
defmodule MyApp.GraphQL.Types.User do
  use Absinthe.Object.Type
  alias Absinthe.Object.Extensions.CQL

  type "User", struct: MyApp.User do
    use CQL

    field :id, non_null(:id)
    field :name, :string
    field :email, :string
    field :age, :integer
    field :active, :boolean
    field :inserted_at, :datetime
  end
end
```

This generates a `UserFilter` input type with appropriate operators for each field.

## Generated Operators

CQL generates operators based on Ecto field types:

| Ecto Type | Generated Operators |
|-----------|---------------------|
| `:string` | `eq`, `neq`, `in`, `contains`, `starts_with`, `ends_with`, `is_nil` |
| `:integer` | `eq`, `neq`, `in`, `gt`, `gte`, `lt`, `lte`, `is_nil` |
| `:boolean` | `eq`, `is_nil` |
| `:id` | `eq`, `neq`, `in` |
| `:naive_datetime`, `:utc_datetime`, `:date` | `eq`, `neq`, `gt`, `gte`, `lt`, `lte`, `is_nil` |
| `Ecto.Enum` | `eq`, `neq`, `in` |

## Custom Filters

Add filters for computed fields or fields not in the Ecto schema:

```elixir
type "User", struct: MyApp.User do
  use CQL

  field :id, non_null(:id)
  field :first_name, :string
  field :last_name, :string
  field :full_name, :string  # Computed field

  # Define custom filter for the computed field
  custom_filter :full_name, [:eq, :contains], fn query, op, value ->
    import Ecto.Query

    case op do
      :eq ->
        from u in query,
          where: fragment("concat(?, ' ', ?)", u.first_name, u.last_name) == ^value

      :contains ->
        from u in query,
          where: ilike(fragment("concat(?, ' ', ?)", u.first_name, u.last_name), ^"%#{value}%")
    end
  end
end
```

### Type Shorthand

Use a type shorthand to get all operators for that type:

```elixir
# Instead of listing operators manually
custom_filter :computed_score, :integer, fn query, op, value ->
  # Gets all integer operators: eq, neq, in, gt, gte, lt, lte, is_nil
  # ... apply filter
end
```

## Authorization Integration

CQL respects your type's authorization rules. Users can only filter on fields they're authorized to see:

```elixir
type "User", struct: MyApp.User do
  use CQL

  authorize fn user, ctx ->
    if ctx[:current_user]?.admin do
      :all
    else
      [:id, :name, :email]  # Non-admins can't see/filter salary
    end
  end

  field :id, non_null(:id)
  field :name, :string
  field :email, :string
  field :salary, :integer  # Only admins can filter on this
end
```

### Validating Filters

Use `__cql_validate_filter__/3` to check if a user can apply certain filters:

```elixir
def list_users(_, %{filter: filter}, %{context: ctx}) do
  case UserType.__cql_validate_filter__(filter, nil, ctx) do
    :ok ->
      # Filter is valid, apply it
      MyApp.Users.list(filter)

    {:error, {:unauthorized_fields, fields}} ->
      {:error, "Cannot filter on: #{inspect(fields)}"}
  end
end
```

### Getting Authorized Fields

Query which fields a user can filter on:

```elixir
# Get all filterable fields for this user
fields = UserType.__cql_authorized_fields__(object, ctx)
# => [:id, :name, :email]

# Get operators for a specific field
ops = UserType.__cql_authorized_operators_for__(:name, object, ctx)
# => [:eq, :neq, :in, :contains, :starts_with, :ends_with, :is_nil]
```

## Custom Scalar Operators

Define CQL operators on custom scalar types:

```elixir
defmodule MyApp.GraphQL.Scalars.GeoPoint do
  use Absinthe.Object.Scalar

  scalar "GeoPoint" do
    parse &parse_point/2
    serialize &serialize_point/1

    # Define operators available for filtering
    operators [:eq, :near, :within_radius, :within_bounds]

    # Define how each operator works
    filter :near, fn field, value, opts ->
      distance = opts[:distance] || 10_000
      {:geo, :st_dwithin, field, value, distance}
    end

    filter :within_radius, fn field, %{center: center, radius: radius} ->
      {:geo, :st_dwithin, field, center, radius}
    end

    filter :within_bounds, fn field, bounds ->
      {:geo, :st_within, field, bounds}
    end
  end

  defp parse_point(%{fields: fields}, _) do
    # ... parse logic
  end

  defp serialize_point(point) do
    # ... serialize logic
  end
end
```

Then use the scalar in your type:

```elixir
type "Location", struct: MyApp.Location do
  use CQL

  field :id, non_null(:id)
  field :name, :string
  field :coordinates, :geo_point  # Uses custom operators
end
```

## API Reference

### Type Functions

| Function | Description |
|----------|-------------|
| `__cql_config__/0` | Returns the CQL configuration for this type |
| `__cql_filterable_fields__/0` | Returns all fields that can be filtered |
| `__cql_operators_for__/1` | Returns operators for a specific field |
| `__cql_authorized_fields__/2` | Returns filterable fields for a user |
| `__cql_authorized_operators_for__/3` | Returns operators a user can use on a field |
| `__cql_validate_filter__/3` | Validates a filter against authorization |
| `__cql_apply_custom_filter__/4` | Applies a custom filter function |

### Configuration

The `__cql_config__/0` function returns:

```elixir
%{
  adapter: Absinthe.Object.Adapters.Ecto,  # Detected adapter
  adapter_fields: [:id, :name, :email],     # Fields from adapter
  adapter_field_types: %{                   # Types for each field
    id: :id,
    name: :string,
    email: :string
  },
  custom_filters: %{                        # Custom filter definitions
    full_name: {[:eq, :contains], fn query, op, value -> ... end}
  }
}
```

## Adapters

CQL uses adapters to detect field information. The built-in Ecto adapter:

- Detects Ecto schemas via `__schema__/1`
- Extracts field types from the schema
- Maps Ecto types to CQL operators

Custom adapters can be created by implementing the `Absinthe.Object.Adapter` behaviour:

```elixir
defmodule MyApp.CustomAdapter do
  use Absinthe.Object.Adapter

  @impl true
  def handles?(module), do: # check if this adapter handles the module

  @impl true
  def queryable_fields(module), do: # return list of field atoms

  @impl true
  def field_type(module, field), do: # return the field type

  @impl true
  def operators_for_type(type), do: # return operators for this type
end
```

Then specify it explicitly:

```elixir
type "Custom", struct: MyApp.Custom do
  use CQL, adapter: MyApp.CustomAdapter

  # ...
end
```

## Best Practices

1. **Use authorization** - Always define authorization when exposing sensitive fields
2. **Validate in resolvers** - Call `__cql_validate_filter__/3` before applying filters
3. **Custom filters for computed fields** - Use `custom_filter` for anything not in the schema
4. **Type shorthands** - Use type names (`:string`, `:integer`) for consistent operators
5. **Document operators** - Help API consumers know what filters are available
