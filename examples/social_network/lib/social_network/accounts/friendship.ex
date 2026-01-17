defmodule SocialNetwork.Accounts.Friendship do
  use Ecto.Schema
  import Ecto.Changeset

  schema "friendships" do
    field :status, Ecto.Enum, values: [:pending, :accepted, :blocked], default: :pending

    belongs_to :user, SocialNetwork.Accounts.User
    belongs_to :friend, SocialNetwork.Accounts.User

    timestamps()
  end

  def changeset(friendship, attrs) do
    friendship
    |> cast(attrs, [:status, :user_id, :friend_id])
    |> validate_required([:user_id, :friend_id])
    |> validate_not_self_friendship()
    |> unique_constraint([:user_id, :friend_id], name: :friendships_unique_pair)
  end

  # Prevent users from friending themselves
  defp validate_not_self_friendship(changeset) do
    user_id = get_field(changeset, :user_id)
    friend_id = get_field(changeset, :friend_id)

    if user_id && friend_id && user_id == friend_id do
      add_error(changeset, :friend_id, "cannot be the same as user")
    else
      changeset
    end
  end
end
