defmodule Absinthe.Object.ScalarTest do
  use ExUnit.Case, async: true

  defmodule DateTimeScalar do
    use Absinthe.Object.Scalar

    scalar "DateTime" do
      parse fn
        %Absinthe.Blueprint.Input.String{value: value} ->
          case DateTime.from_iso8601(value) do
            {:ok, datetime, _} -> {:ok, datetime}
            _ -> :error
          end

        %Absinthe.Blueprint.Input.Null{} ->
          {:ok, nil}

        _ ->
          :error
      end

      serialize fn datetime ->
        DateTime.to_iso8601(datetime)
      end
    end
  end

  defmodule MoneyScalar do
    use Absinthe.Object.Scalar

    scalar "Money", description: "A monetary value in cents" do
      parse fn
        %Absinthe.Blueprint.Input.Integer{value: value} ->
          {:ok, value}

        %Absinthe.Blueprint.Input.String{value: value} ->
          case Integer.parse(value) do
            {int, ""} -> {:ok, int}
            _ -> :error
          end

        %Absinthe.Blueprint.Input.Null{} ->
          {:ok, nil}

        _ ->
          :error
      end

      serialize fn cents ->
        cents
      end
    end
  end

  defmodule TestSchema do
    use Absinthe.Schema

    import_types DateTimeScalar
    import_types MoneyScalar

    query do
      field :current_time, :date_time do
        resolve fn _, _, _ ->
          {:ok, DateTime.utc_now()}
        end
      end

      field :parse_time, :date_time do
        arg :time, non_null(:date_time)

        resolve fn _, %{time: time}, _ ->
          {:ok, time}
        end
      end

      field :price, :money do
        resolve fn _, _, _ ->
          {:ok, 1999}
        end
      end

      field :parse_price, :money do
        arg :amount, non_null(:money)

        resolve fn _, %{amount: amount}, _ ->
          {:ok, amount}
        end
      end
    end
  end

  describe "scalar/2 macro" do
    test "defines __absinthe_object_definition__/0" do
      definition = DateTimeScalar.__absinthe_object_definition__()

      assert definition.kind == :scalar
      assert definition.name == "DateTime"
      assert definition.identifier == :date_time
    end

    test "defines __absinthe_object_identifier__/0" do
      assert DateTimeScalar.__absinthe_object_identifier__() == :date_time
    end

    test "defines __absinthe_object_kind__/0" do
      assert DateTimeScalar.__absinthe_object_kind__() == :scalar
    end
  end

  describe "Absinthe integration" do
    test "generates valid Absinthe scalar type" do
      type = Absinthe.Schema.lookup_type(TestSchema, :date_time)

      assert type != nil
      assert type.name == "DateTime"
      assert type.identifier == :date_time
    end

    test "serializes output correctly" do
      query = """
      {
        currentTime
      }
      """

      assert {:ok, %{data: data}} = Absinthe.run(query, TestSchema)
      # Should be an ISO8601 string
      assert is_binary(data["currentTime"])
      assert String.contains?(data["currentTime"], "T")
    end

    test "parses input correctly" do
      query = """
      {
        parseTime(time: "2024-01-15T12:00:00Z")
      }
      """

      assert {:ok, %{data: data}} = Absinthe.run(query, TestSchema)
      assert data["parseTime"] == "2024-01-15T12:00:00Z"
    end

    test "returns error for invalid input" do
      query = """
      {
        parseTime(time: "not a date")
      }
      """

      assert {:ok, %{errors: errors}} = Absinthe.run(query, TestSchema)
      assert errors != []
    end

    test "money scalar works with integers" do
      query = """
      {
        parsePrice(amount: 999)
      }
      """

      assert {:ok, %{data: data}} = Absinthe.run(query, TestSchema)
      assert data["parsePrice"] == 999
    end
  end
end
