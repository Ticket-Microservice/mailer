defmodule Mailer.Email do
  alias Mailer.GmailOAuth2
  import Swoosh.Email
  alias Mailer.Mailer, as: MailerModule

  def welcome_email(to_email) do
    access_token = GmailOAuth2.get_access_token()
    |> IO.inspect(label: "token")
    new()
    |> to({"Tony Stark", to_email})
    |> from("your-email@gmail.com")
    |> subject("Welcome to MyApp!")
    |> html_body("<h1>Welcome!</h1>")
    |> text_body("Welcome!")
    |> IO.inspect(label: "email")
    |> MailerModule.deliver(access_token: access_token)
  end

end
