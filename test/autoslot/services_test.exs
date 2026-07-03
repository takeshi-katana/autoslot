defmodule Autoslot.ServicesTest do
  use Autoslot.DataCase

  alias Autoslot.Services

  describe "services" do
    alias Autoslot.Services.Service

    import Autoslot.ServicesFixtures

    @invalid_attrs %{name: nil, description: nil, duration_minutes: nil, price: nil}

    test "list_services/0 returns all services" do
      service = service_fixture()
      assert Services.list_services() == [service]
    end

    test "get_service!/1 returns the service with given id" do
      service = service_fixture()
      assert Services.get_service!(service.id) == service
    end

    test "create_service/1 with valid data creates a service" do
      valid_attrs = %{
        name: "some name",
        description: "some description",
        duration_minutes: 42,
        price: 42
      }

      assert {:ok, %Service{} = service} = Services.create_service(valid_attrs)
      assert service.name == "some name"
      assert service.description == "some description"
      assert service.duration_minutes == 42
      assert service.price == 42
    end

    test "create_service/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Services.create_service(@invalid_attrs)
    end

    test "update_service/2 with valid data updates the service" do
      service = service_fixture()

      update_attrs = %{
        name: "some updated name",
        description: "some updated description",
        duration_minutes: 43,
        price: 43
      }

      assert {:ok, %Service{} = service} = Services.update_service(service, update_attrs)
      assert service.name == "some updated name"
      assert service.description == "some updated description"
      assert service.duration_minutes == 43
      assert service.price == 43
    end

    test "update_service/2 with invalid data returns error changeset" do
      service = service_fixture()
      assert {:error, %Ecto.Changeset{}} = Services.update_service(service, @invalid_attrs)
      assert service == Services.get_service!(service.id)
    end

    test "delete_service/1 deletes the service" do
      service = service_fixture()
      assert {:ok, %Service{}} = Services.delete_service(service)
      assert_raise Ecto.NoResultsError, fn -> Services.get_service!(service.id) end
    end

    test "change_service/1 returns a service changeset" do
      service = service_fixture()
      assert %Ecto.Changeset{} = Services.change_service(service)
    end
  end
end
