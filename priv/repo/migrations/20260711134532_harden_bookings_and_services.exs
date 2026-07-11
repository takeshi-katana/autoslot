defmodule Autoslot.Repo.Migrations.HardenBookingsAndServices do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS btree_gist"
    execute "CREATE EXTENSION IF NOT EXISTS pgcrypto"

    alter table(:services) do
      modify :name, :string, null: false
      modify :description, :text, null: false
      modify :duration_minutes, :integer, null: false
      modify :price, :integer, null: false
    end

    alter table(:bookings) do
      modify :customer_name, :string, null: false
      modify :phone, :string, null: false
      modify :vehicle_plate, :string, null: false
      modify :starts_at, :utc_datetime, null: false
      modify :ends_at, :utc_datetime, null: false
      modify :status, :string, null: false, default: "pending"
      modify :service_id, :bigint, null: false
      add :public_token, :uuid
    end

    execute "UPDATE bookings SET public_token = gen_random_uuid() WHERE public_token IS NULL"
    alter table(:bookings), do: modify(:public_token, :uuid, null: false)

    create unique_index(:bookings, [:public_token])
    create index(:bookings, [:starts_at])
    create index(:bookings, [:status])
    create index(:bookings, [:phone])

    create constraint(:bookings, :bookings_status_check,
             check: "status IN ('pending', 'confirmed', 'cancelled')"
           )

    execute """
    ALTER TABLE bookings ADD CONSTRAINT bookings_no_overlapping_active_times
    EXCLUDE USING gist (tsrange(starts_at, ends_at, '[)') WITH &&)
    WHERE (status <> 'cancelled')
    """
  end

  def down do
    execute "ALTER TABLE bookings DROP CONSTRAINT IF EXISTS bookings_no_overlapping_active_times"
    drop constraint(:bookings, :bookings_status_check)
    drop unique_index(:bookings, [:public_token])
    drop index(:bookings, [:starts_at])
    drop index(:bookings, [:status])
    drop index(:bookings, [:phone])
    alter table(:bookings), do: remove(:public_token)
  end
end
