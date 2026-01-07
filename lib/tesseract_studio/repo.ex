defmodule TesseractStudio.Repo do
  use Ecto.Repo,
    otp_app: :tesseract_studio,
    adapter: Ecto.Adapters.Postgres
end
