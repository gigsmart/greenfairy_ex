defmodule Absinthe.Object.Field.Loader do
  @moduledoc """
  Custom loader support for field resolution.

  Provides a `loader` macro that can be used within field blocks to define
  custom batch loading functions, replacing the default DataLoader behavior.

  ## Usage

  Within a field definition, use `loader` to provide a custom batch function:

      field :nearby_gigs, list_of(:gig) do
        arg :location, non_null(:geo_point)
        arg :radius, :integer, default_value: 10

        loader fn worker, args, ctx ->
          MyApp.Gigs.batch_load_nearby(worker.id, args.location, args.radius)
        end
      end

  ## Function Signatures

  The loader function can have different arities:

  **2-arity** - `(parent, args)` - Simple loader without context:

      loader fn user, args ->
        MyApp.load_posts(user.id, args)
      end

  **3-arity** - `(parent, args, context)` - Full access to context:

      loader fn user, args, ctx ->
        MyApp.load_posts(user.id, args, ctx[:current_user])
      end

  ## Module/Function Reference

  You can also reference a module and function:

      loader {MyApp.Loaders.Gigs, :nearby}

  The function will be called with `(parent, args, context)`.

  ## DataLoader Integration

  For batch loading that integrates with DataLoader, use `dataloader/0` instead:

      field :posts, list_of(:post) do
        dataloader()  # Uses adapter-detected source
      end

      field :active_posts, list_of(:post) do
        dataloader source: :custom_source, args: %{status: :active}
      end

  """

  @doc """
  Defines a custom loader function for a field.

  ## Examples

      # Anonymous function
      loader fn parent, args, ctx ->
        MyApp.batch_load(parent.id, args)
      end

      # Module/function reference
      loader {MyApp.Loaders, :load_items}

  """
  defmacro loader(func) do
    case func do
      {module, function} when is_atom(function) ->
        # Module/function tuple
        quote do
          resolve fn parent, args, %{context: context} ->
            apply(unquote(module), unquote(function), [parent, args, context])
          end
        end

      _ ->
        # Anonymous function or function capture
        quote do
          resolve fn parent, args, %{context: context} = resolution ->
            loader_fn = unquote(func)

            case :erlang.fun_info(loader_fn, :arity) do
              {:arity, 2} ->
                loader_fn.(parent, args)

              {:arity, 3} ->
                loader_fn.(parent, args, context)

              _ ->
                raise ArgumentError,
                      "loader function must have arity 2 (parent, args) or 3 (parent, args, context)"
            end
          end
        end
    end
  end

  @doc """
  Creates a batch loader that groups multiple calls together.

  This is useful when you want custom batching logic but still want
  to batch multiple parent objects together.

  ## Example

      field :stats, :user_stats do
        batch_loader fn user_ids, args, ctx ->
          MyApp.Stats.batch_load(user_ids, args)
        end
      end

  """
  defmacro batch_loader(func) do
    quote do
      resolve fn parent, args, %{context: context} ->
        batch_fn = unquote(func)

        # Use Absinthe's batch helper
        Absinthe.Resolution.Helpers.batch(
          {__MODULE__, :__batch_loader__, [batch_fn, args, context]},
          parent,
          fn results ->
            {:ok, Map.get(results, parent)}
          end
        )
      end
    end
  end

  @doc false
  def __batch_loader__(batch_fn, args, context, parents) do
    results = batch_fn.(parents, args, context)

    # Convert results to a map keyed by parent if it's a list
    case results do
      %{} = map -> map
      list when is_list(list) -> Enum.zip(parents, list) |> Map.new()
      _ -> %{}
    end
  end
end
