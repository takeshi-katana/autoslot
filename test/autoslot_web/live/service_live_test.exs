defmodule AutoslotWeb.ServiceLiveTest do
  use AutoslotWeb.ConnCase

  import Phoenix.LiveViewTest
  import Autoslot.ServicesFixtures

  @create_attrs %{
    name: "Компьютерная диагностика",
    description: "Проверка электронных систем автомобиля",
    duration_minutes: 30,
    price: 1500
  }
  @update_attrs %{
    name: "Замена масла",
    description: "Замена моторного масла и фильтра",
    duration_minutes: 60,
    price: 2500
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

      assert html =~ "Каталог услуг"
      assert html =~ service.name
    end

    test "saves new service", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/services")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "Добавить услугу")
               |> render_click()
               |> follow_redirect(conn, ~p"/services/new")

      assert render(form_live) =~ "Новая услуга"

      assert form_live
             |> form("#service-form", service: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#service-form", service: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/services")

      html = render(index_live)
      assert html =~ "Компьютерная диагностика"
      assert html =~ "30 мин."
      assert html =~ "1500 ₽"
    end

    test "updates service in listing", %{conn: conn, service: service} do
      {:ok, index_live, _html} = live(conn, ~p"/services")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#services-#{service.id} a", "Редактировать")
               |> render_click()
               |> follow_redirect(conn, ~p"/services/#{service}/edit")

      assert render(form_live) =~ "Редактирование услуги"

      assert form_live
             |> form("#service-form", service: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#service-form", service: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/services")

      html = render(index_live)
      assert html =~ "Замена масла"
      assert html =~ "60 мин."
      assert html =~ "2500 ₽"
    end

    test "deletes service in listing", %{conn: conn, service: service} do
      {:ok, index_live, _html} = live(conn, ~p"/services")

      assert index_live |> element("#services-#{service.id} button", "Удалить") |> render_click()
      refute has_element?(index_live, "#services-#{service.id}")
    end
  end

  describe "Show" do
    setup [:create_service]

    test "displays service", %{conn: conn, service: service} do
      {:ok, _show_live, html} = live(conn, ~p"/services/#{service}")

      assert html =~ service.name
      assert html =~ "Параметры услуги"
      assert html =~ "Описание"
    end

    test "updates service and returns to show", %{conn: conn, service: service} do
      {:ok, form_live, _html} = live(conn, ~p"/services/#{service}/edit?return_to=show")

      assert render(form_live) =~ "Редактирование услуги"

      assert form_live
             |> form("#service-form", service: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#service-form", service: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/services/#{service}")

      html = render(show_live)
      assert html =~ "Замена масла"
      assert html =~ "60 мин."
      assert html =~ "2500 ₽"
    end
  end
end
