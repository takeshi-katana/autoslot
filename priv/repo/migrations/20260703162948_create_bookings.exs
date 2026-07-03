defmodule Autoslot.Repo.Migrations.CreateBookings do
  use Ecto.Migration

  def change do
    create table(:bookings) do
      add :customer_name, :string
      add :phone, :string
      add :vehicle_plate, :string
      add :starts_at, :utc_datetime
      add :ends_at, :utc_datetime
      add :status, :string
      add :service_id, references(:services, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:bookings, [:service_id])
  end
end
