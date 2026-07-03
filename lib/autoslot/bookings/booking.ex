defmodule Autoslot.Bookings.Booking do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bookings" do
    field :customer_name, :string
    field :phone, :string
    field :vehicle_plate, :string
    field :starts_at, :utc_datetime
    field :ends_at, :utc_datetime
    field :status, :string
    field :service_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(booking, attrs) do
    booking
    |> cast(attrs, [:customer_name, :phone, :vehicle_plate, :starts_at, :ends_at, :status])
    |> validate_required([:customer_name, :phone, :vehicle_plate, :starts_at, :ends_at, :status])
  end
end
