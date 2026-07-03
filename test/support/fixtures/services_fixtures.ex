defmodule Autoslot.ServicesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Autoslot.Services` context.
  """

  @doc """
  Generate a service.
  """
  def service_fixture(attrs \\ %{}) do
    {:ok, service} =
      attrs
      |> Enum.into(%{
        description: "some description",
        duration_minutes: 42,
        name: "some name",
        price: 42
      })
      |> Autoslot.Services.create_service()

    service
  end
end
