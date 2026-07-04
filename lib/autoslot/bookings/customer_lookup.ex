defmodule Autoslot.Bookings.CustomerLookup do
  @moduledoc """
  Customer-facing lookup functions for bookings.

  The public page uses this module to find bookings by phone number and cancel
  active bookings without exposing the full admin booking management interface.
  """

  import Ecto.Query, warn: false

  alias Autoslot.Bookings.Booking
  alias Autoslot.Repo

  @active_statuses ["pending", "confirmed"]

  def list_by_phone(phone) do
    phone
    |> phone_query()
    |> case do
      nil ->
        []

      query ->
        query
        |> order_by([b], desc: b.starts_at)
        |> preload(:service)
        |> Repo.all()
    end
  end

  def cancel_by_phone(booking_id, phone) do
    booking = get_by_phone(booking_id, phone)

    cond do
      is_nil(booking) ->
        {:error, :not_found}

      booking.status == "cancelled" ->
        {:error, :already_cancelled}

      booking.status not in @active_statuses ->
        {:error, :not_cancellable}

      true ->
        booking
        |> Booking.changeset(%{status: "cancelled"})
        |> Repo.update()
    end
  end

  def get_by_phone(booking_id, phone) do
    phone
    |> phone_query()
    |> case do
      nil ->
        nil

      query ->
        query
        |> where([b], b.id == ^booking_id)
        |> preload(:service)
        |> Repo.one()
    end
  end

  def active?(%Booking{status: status}), do: status in @active_statuses

  def normalize_phone(phone) when is_binary(phone) do
    digits = Regex.replace(~r/\D+/, phone, "")

    if String.length(digits) > 10 do
      String.slice(digits, -10, 10)
    else
      digits
    end
  end

  def normalize_phone(_phone), do: ""

  defp phone_query(phone) do
    normalized_phone = normalize_phone(phone)

    cond do
      normalized_phone == "" ->
        nil

      String.length(normalized_phone) >= 10 ->
        from b in Booking,
          where:
            fragment(
              "right(regexp_replace(?, '[^0-9]+', '', 'g'), 10)",
              b.phone
            ) == ^normalized_phone

      true ->
        from b in Booking,
          where:
            fragment(
              "regexp_replace(?, '[^0-9]+', '', 'g')",
              b.phone
            ) == ^normalized_phone
    end
  end
end
