defmodule MyAwesomeListWeb.PageView do
  use MyAwesomeListWeb, :view

  @spec anchor(String.t()) :: String.t()
  def anchor(name) when is_binary(name) do
    String.downcase(name) |> String.replace(" ", "-")
  end

  @spec description(String.t()) :: String.t()
  def description(string) when is_binary(string) do
      Regex.replace(~r/^[ -]{1,3}/, string, "")
  end

  def unknown?(:unknown), do: "?"
  def unknown?(nil), do: "?"
  def unknown?(s), do: s
end
