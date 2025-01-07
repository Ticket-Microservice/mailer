defmodule MailerWeb.Controller.Email do
  use MailerWeb, :controller
  alias Mailer.Email, as: EmailApp
  alias Mailer.GmailOAuth2
  require Logger

  def welcome_email(conn, params) do
    try do
      EmailApp.welcome_email(params["email"])
      |> IO.inspect(label: "resp")

      conn
      |> put_status(:ok)
      |> json(%{
        data: %{
        },
        message: "success"
      })

    rescue
      e ->
        Logger.error(e)

        conn
        |> put_status(:internal_server_error)
        |> json(%{message: e.message})
    end
  end

  def get_consent_link(conn, params) do
    try do
      data = GmailOAuth2.generate_consent_link()

      conn
      |> put_status(:ok)
      |> json(%{
        data: %{
          data: data
        },
        message: "success"
      })

    rescue
      e ->
        Logger.error(e)

        conn
        |> put_status(:internal_server_error)
        |> json(%{message: e.message})
    end
  end


end
