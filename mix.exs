defmodule Absinthe.Object.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/gigsmart/absinthe_object"

  def project do
    [
      app: :absinthe_object,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs(),
      name: "Absinthe.Object",
      description: "A cleaner DSL for GraphQL schema definitions built on Absinthe",
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:absinthe, "~> 1.7"},
      {:dataloader, "~> 2.0"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["GigSmart"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "PLAN.md"]
    ]
  end
end
