defmodule SocialNetworkWeb.GraphQL.DataLoader do
  @moduledoc """
  DataLoader configuration for the social network GraphQL API.

  This module sets up Ecto-based data loading with batching to avoid N+1 queries.
  """

  alias SocialNetwork.Repo

  def new do
    Dataloader.new()
    |> Dataloader.add_source(:repo, ecto_source())
  end

  defp ecto_source do
    Dataloader.Ecto.new(Repo, query: &query/2)
  end

  # Customize queries before they're executed by DataLoader.
  # This is the place to apply common filters or authorization scoping.
  #
  # Examples of what you might do here in production:
  #   - Soft delete filtering: where(queryable, [q], is_nil(q.deleted_at))
  #   - Multi-tenancy scoping: where(queryable, [q], q.tenant_id == ^params.tenant_id)
  #   - Authorization: filter based on current user's permissions
  #   - Default ordering: order_by(queryable, [q], desc: q.inserted_at)
  defp query(queryable, _params) do
    queryable
  end
end
