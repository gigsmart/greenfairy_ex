defmodule GreenFairy.CQL.OrderBuilder do
  @moduledoc """
  Builds Ecto order_by clauses from CQL order input.

  Transforms CQL order specifications into Ecto query order_by clauses,
  supporting simple field ordering, direction modifiers, null positioning,
  and association ordering.

  ## Input Format

  Order input is a list of field-direction maps:

      [
        %{name: %{direction: :asc}},
        %{age: %{direction: :desc}}
      ]

  ## Association Ordering

  Order by fields on associated records:

      [
        %{author: %{username: %{direction: :asc}}}
      ]

  This joins the `author` association and orders by `author.username`.

  ## Example

      iex> order = [%{name: %{direction: :asc}}]
      iex> OrderBuilder.apply_order(query, order, User)
      #Ecto.Query<from u in User, order_by: [asc: u.name]>
  """

  import Ecto.Query
  alias GreenFairy.CQL.OrderOperator

  @doc """
  Applies CQL order specifications to an Ecto query.

  ## Parameters

  - `query` - Base Ecto query
  - `order_specs` - List of order specification maps
  - `schema` - The schema module for field lookups (required for association ordering)
  - `opts` - Additional options (optional)

  ## Returns

  The ordered Ecto query.
  """
  def apply_order(query, order_specs, schema \\ nil, opts \\ [])
  def apply_order(query, nil, _schema, _opts), do: query
  def apply_order(query, [], _schema, _opts), do: query

  def apply_order(query, order_specs, schema, opts) when is_list(order_specs) do
    # Parse order specs into OrderOperator structs
    order_operators =
      order_specs
      |> Enum.flat_map(fn spec -> parse_order_spec(spec, schema) end)
      |> Enum.reject(&is_nil/1)

    if Enum.empty?(order_operators) do
      query
    else
      # Separate association orders from regular orders
      {assoc_orders, _regular_orders} =
        Enum.split_with(order_operators, &OrderOperator.association_order?/1)

      # Apply joins for association orders
      query = apply_association_joins(query, assoc_orders, schema)

      # Build all order expressions
      order_exprs =
        Enum.map(order_operators, fn op ->
          build_order_expr(op, schema, opts)
        end)

      # Apply all order expressions in a single order_by
      order_by(query, ^order_exprs)
    end
  end

  # Parse a single order spec (e.g., %{name: %{direction: :asc}})
  defp parse_order_spec(spec, schema) when is_map(spec) do
    spec
    |> Enum.map(fn {field, args} ->
      # Skip logical operators and non-field keys
      if field in [:_and, :_or, :_not] or not is_atom(field) do
        nil
      else
        parse_field_order(field, args, schema, [])
      end
    end)
  end

  defp parse_order_spec(_, _schema), do: []

  # Parse field order arguments, detecting associations
  defp parse_field_order(field, args, schema, path) when is_map(args) do
    cond do
      # Check if this has a direction key - it's a terminal order spec
      Map.has_key?(args, :direction) ->
        if path == [] do
          OrderOperator.from_input(field, args)
        else
          %OrderOperator{
            field: field,
            direction: Map.get(args, :direction, :asc),
            priority: Map.get(args, :priority, []),
            association_path: Enum.reverse(path)
          }
        end

      # Check if field is an association and args is nested
      schema != nil and association?(schema, field) ->
        # Recurse into the association
        assoc = schema.__schema__(:association, field)
        related_schema = get_related_schema(assoc)
        new_path = [field | path]

        # Find the nested field/args
        args
        |> Enum.map(fn {nested_field, nested_args} ->
          parse_field_order(nested_field, nested_args, related_schema, new_path)
        end)
        |> List.first()

      # Regular field without direction - assume asc
      true ->
        OrderOperator.from_input(field, %{direction: :asc})
    end
  end

  defp parse_field_order(field, direction, _schema, path) when is_atom(direction) do
    if path == [] do
      OrderOperator.from_input(field, %{direction: direction})
    else
      %OrderOperator{
        field: field,
        direction: direction,
        association_path: Enum.reverse(path)
      }
    end
  end

  defp parse_field_order(_, _, _, _), do: nil

  # Check if a field is an association
  defp association?(schema, field) do
    case schema.__schema__(:association, field) do
      nil -> false
      _ -> true
    end
  rescue
    _ -> false
  end

  # Get the related schema from an association
  defp get_related_schema(%{related: related}), do: related
  defp get_related_schema(%{queryable: queryable}), do: queryable
  defp get_related_schema(_), do: nil

  # Apply joins for association orders
  defp apply_association_joins(query, [], _schema), do: query

  defp apply_association_joins(query, assoc_orders, schema) do
    # Get unique association paths
    paths =
      assoc_orders
      |> Enum.map(& &1.association_path)
      |> Enum.uniq()

    # Apply joins for each path, avoiding duplicates
    Enum.reduce(paths, query, fn path, acc ->
      join_association_path(acc, path, schema)
    end)
  end

  # Join an association path (e.g., [:author] or [:author, :organization])
  defp join_association_path(query, path, schema) do
    Enum.reduce(path, {query, schema}, fn assoc_name, {acc_query, current_schema} ->
      assoc = current_schema.__schema__(:association, assoc_name)
      related_schema = get_related_schema(assoc)

      # Check if this association is already joined
      if Ecto.Query.has_named_binding?(acc_query, assoc_name) do
        {acc_query, related_schema}
      else
        joined_query =
          from(q in acc_query,
            left_join: a in assoc(q, ^assoc_name),
            as: ^assoc_name
          )

        {joined_query, related_schema}
      end
    end)
    |> elem(0)
  end

  # Build a single order expression (to be used in order_by)
  defp build_order_expr(%OrderOperator{association_path: []} = op, _schema, _opts) do
    # Regular field order
    field = op.field
    direction = OrderOperator.to_ecto_direction(op.direction)

    {direction, dynamic([q], field(q, ^field))}
  end

  defp build_order_expr(%OrderOperator{association_path: path} = op, _schema, _opts) do
    # Association field order - use the last association as the binding
    binding = List.last(path)
    field = op.field
    direction = OrderOperator.to_ecto_direction(op.direction)

    # Build dynamic with named binding
    {direction, dynamic([{^binding, x}], field(x, ^field))}
  end
end
