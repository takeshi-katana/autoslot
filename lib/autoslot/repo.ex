defmodule Autoslot.Repo do
  use Ecto.Repo,
    otp_app: :autoslot,
    adapter: Ecto.Adapters.Postgres
end
