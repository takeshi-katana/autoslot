defmodule Autoslot.Services.Service do
  use Ecto.Schema
  import Ecto.Changeset

  schema "services" do
    field :name, :string
    field :description, :string
    field :duration_minutes, :integer
    field :price, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(service, attrs) do
    service
    |> cast(attrs, [:name, :description, :duration_minutes, :price])
    |> validate_required([:name, :description, :duration_minutes, :price])
  end
end
