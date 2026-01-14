defmodule Mix.Tasks.Absinthe.Object.GenTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Absinthe.Object.Gen

  describe "parse_field/1" do
    test "parses simple field" do
      assert %{name: "email", type: :string, modifier: nil, related: nil} =
               Gen.parse_field("email:string")
    end

    test "parses required field" do
      assert %{name: "email", type: :string, modifier: :required, related: nil} =
               Gen.parse_field("email:string:required")
    end

    test "parses has_many relationship" do
      assert %{name: "posts", type: :has_many, modifier: nil, related: "Post"} =
               Gen.parse_field("posts:has_many:Post")
    end

    test "parses belongs_to relationship" do
      assert %{name: "org", type: :belongs_to, modifier: nil, related: "Organization"} =
               Gen.parse_field("org:belongs_to:Organization")
    end

    test "parses connection" do
      assert %{name: "friends", type: :connection, modifier: nil, related: "User"} =
               Gen.parse_field("friends:connection:User")
    end

    test "parses enum field" do
      assert %{name: "status", type: :enum, modifier: nil, related: "UserStatus"} =
               Gen.parse_field("status:enum:UserStatus")
    end

    test "parses field with only name as string" do
      assert %{name: "name", type: :string, modifier: nil, related: nil} =
               Gen.parse_field("name")
    end
  end

  describe "field_to_code/1" do
    test "generates simple field code" do
      field = %{name: "email", type: :string, modifier: nil, related: nil}
      assert Gen.field_to_code(field) == "field :email, :string"
    end

    test "generates required field code" do
      field = %{name: "email", type: :string, modifier: :required, related: nil}
      assert Gen.field_to_code(field) == "field :email, :string, null: false"
    end

    test "generates has_many code" do
      field = %{name: "posts", type: :has_many, modifier: nil, related: "Post"}
      code = Gen.field_to_code(field)
      assert code =~ "has_many :posts"
      assert code =~ "Types.Post"
    end

    test "generates belongs_to code" do
      field = %{name: "org", type: :belongs_to, modifier: nil, related: "Organization"}
      code = Gen.field_to_code(field)
      assert code =~ "belongs_to :org"
      assert code =~ "Types.Organization"
    end

    test "generates connection code" do
      field = %{name: "friends", type: :connection, modifier: nil, related: "User"}
      code = Gen.field_to_code(field)
      assert code =~ "connection :friends"
      assert code =~ "Types.User"
    end
  end

  describe "to_file_name/1" do
    test "converts PascalCase to snake_case" do
      assert Gen.to_file_name("User") == "user"
      assert Gen.to_file_name("UserProfile") == "user_profile"
      assert Gen.to_file_name("BlogPost") == "blog_post"
    end
  end
end
