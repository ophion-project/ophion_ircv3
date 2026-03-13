defmodule Ophion.IRCv3.MixProject do
  use Mix.Project

  def project do
    [
      app: :ophion_ircv3,
      version: "0.1.2",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: "A module providing IRCv3 message parsing and composition."
    ]
  end

  def package do
    [
      maintainers: ["Ariadne Conill"],
      licenses: ["BSD-3-Clause"],
      links: %{
        "GitHub" => "https://github.com/ophion-project/ophion_ircv3",
        "Issues" => "https://github.com/ophion-project/ophion_ircv3/issues"
      }
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
