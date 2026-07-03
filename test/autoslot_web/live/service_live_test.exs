defmodule AutoslotWeb.ServiceLiveTest do
  use AutoslotWeb.ConnCase

  import Phoenix.LiveViewTest
  import Autoslot.ServicesFixtures

  @create_attrs %{
    name: "some name",
    description: "some description",
    duration_minutes: 42,
    price: 42
  }
  @update_attrs %{
    name: "some updated name",
    description: "some updated description",
    duration_minutes: 43,
    price: 43
  }
  @invalid_attrs %{name: nil, description: nil, duration_minutes: nil, price: nil}
  defp create_service(_) do
    service = service_fixture()

    %{service: service}
  end

  describe "Index" do
    setup [:create_service]

    test "lists all services", %{conn: conn, service: service} do
      {:ok, _index_live, html} = live(conn, ~p"/services")

      assert html =~ "Listing Services"
      assert html =~ service.name
    end

    test "saves new service", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/services")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Service")
               |> render_click()
               |> follow_redirect(conn, ~p"/services/new")

      assert render(form_live) =~ "New Service"

      assert form_live
             |> form("#service-form", service: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#service-form", service: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/services")

      html = render(index_live)
      assert html =~ "Service created successfully"
      assert html =~ "some name"
    end

    test "updates service in listing", %{conn: conn, service: service} do
      {:ok, index_live, _html} = live(conn, ~p"/services")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#services-#{service.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/services/#{service}/edit")

      assert render(form_live) =~ "Edit Service"

      assert form_live
             |> form("#service-form", service: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#service-form", service: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/services")

      html = render(index_live)
      assert html =~ "Service updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes service in listing", %{conn: conn, service: service} do
      {:ok, index_live, _html} = live(conn, ~p"/services")

      assert index_live |> element("#services-#{service.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#services-#{service.id}")
    end
  end

  describe "Show" do
    setup [:create_service]

    test "displays service", %{conn: conn, service: service} do
      {:ok, _show_live, html} = live(conn, ~p"/services/#{service}")

      assert html =~ "Show Service"
      assert html =~ service.name
    end

    test "updates service and returns to show", %{conn: conn, service: service} do
      {:ok, show_live, _html} = live(conn, ~p"/services/#{service}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/services/#{service}/edit?return_to=show")

      assert render(form_live) =~ "Edit Service"

      assert form_live
             |> form("#service-form", service: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#service-form", service: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/services/#{service}")

      html = render(show_live)
      assert html =~ "Service updated successfully"
      assert html =~ "some updated name"
    end
  end
end
