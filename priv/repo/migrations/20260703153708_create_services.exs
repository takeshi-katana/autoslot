defmodule Autoslot.Repo.Migrations.CreateServices do
  use Ecto.Migration

  def change do
    create table(:services) do
      add :name, :string
      add :description, :text
      add :duration_minutes, :integer
      add :price, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
