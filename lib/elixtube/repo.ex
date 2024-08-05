defmodule Elixtube.Repo do
  use Ecto.Repo,
    otp_app: :elixtube,
    adapter: Ecto.Adapters.SQLite3
end
