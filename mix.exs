defmodule ElixirGrpc.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_rpc,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:grpc, "~> 0.10.1"},
      {:protobuf, "~> 0.14.1"}
    ]
  end
end
