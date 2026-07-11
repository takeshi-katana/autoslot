defmodule Autoslot.Services.Service do
  use Ecto.Schema
  import Ecto.Changeset

  alias Autoslot.Bookings.Booking

  schema "services" do
    field :name, :string
    field :description, :string
    field :duration_minutes, :integer
    field :price, :integer

    has_many :bookings, Booking

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(service, attrs) do
    service
    |> cast(attrs, [:name, :description, :duration_minutes, :price])
    |> validate_required([:name, :description, :duration_minutes, :price])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:description, min: 2, max: 2_000)
    |> validate_number(:duration_minutes, greater_than: 0, less_than_or_equal_to: 480)
    |> validate_number(:price, greater_than_or_equal_to: 0, less_than_or_equal_to: 10_000_000)
  end
end
