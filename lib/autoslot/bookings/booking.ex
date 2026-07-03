defmodule Autoslot.Bookings.Booking do
  use Ecto.Schema
  import Ecto.Changeset

  alias Autoslot.Services.Service

  @valid_statuses ["pending", "confirmed", "cancelled"]

  schema "bookings" do
    field :customer_name, :string
    field :phone, :string
    field :vehicle_plate, :string
    field :starts_at, :utc_datetime
    field :ends_at, :utc_datetime
    field :status, :string, default: "pending"

    belongs_to :service, Service

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(booking, attrs) do
    booking
    |> cast(attrs, [
      :customer_name,
      :phone,
      :vehicle_plate,
      :starts_at,
      :ends_at,
      :status,
      :service_id
    ])
    |> validate_required([
      :customer_name,
      :phone,
      :vehicle_plate,
      :starts_at,
      :ends_at,
      :status,
      :service_id
    ])
    |> validate_length(:customer_name, min: 2, max: 100)
    |> validate_length(:phone, min: 5, max: 30)
    |> validate_length(:vehicle_plate, min: 3, max: 20)
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_time_range()
    |> foreign_key_constraint(:service_id)
  end

  defp validate_time_range(changeset) do
    starts_at = get_field(changeset, :starts_at)
    ends_at = get_field(changeset, :ends_at)

    case {starts_at, ends_at} do
      {%DateTime{} = starts_at, %DateTime{} = ends_at} ->
        if DateTime.compare(ends_at, starts_at) == :gt do
          changeset
        else
          add_error(changeset, :ends_at, "must be after start time")
        end

      _ ->
        changeset
    end
  end
end
