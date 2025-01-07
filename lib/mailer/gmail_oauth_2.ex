defmodule Mailer.GmailOAuth2 do

  @client_id Application.get_env(:mailer, Mailer.GmailOAuth2)[:client_id]
  @client_secret Application.get_env(:mailer, Mailer.GmailOAuth2)[:client_secret]
  @redirect_url Application.get_env(:mailer, Mailer.GmailOAuth2)[:redirect_uri]
  @auth_url Application.get_env(:mailer, Mailer.GmailOAuth2)[:auth_url]
  @token_url Application.get_env(:mailer, Mailer.GmailOAuth2)[:token_url]
  @refresh_token Application.get_env(:mailer, Mailer.GmailOAuth2)[:refresh_token]
  @dets_table "oauth_token"

  def start_dets do
    :dets.open_file(@dets_table, type: :set, file: ~c"access_tokens.dets")
  end

  def generate_consent_link() do
    client =
      OAuth2.Client.new(
        strategy: OAuth2.Strategy.AuthCode,
        client_id: @client_id,
        client_secret: @client_secret,
        site: "https://www.googleapis.com",
        redirect_uri: @redirect_url,
        authorize_url: @auth_url,
        token_url: @token_url
      )
      |> OAuth2.Client.authorize_url!(scope: "https://mail.google.com/", access_type: "offline")
  end

  def get_access_token() do
    with [{:access_token, token, expires_at}] <- :dets.lookup(@dets_table, :access_token),
         false <- expired?(expires_at) do
       token
    else
      _ -> refresh_and_store_token()
    end
    # |>IO.inspect(label: "cek")
  end

  defp expired?(expires_at) do
    current_time = :os.system_time(:seconds)
    current_time >= expires_at
  end

  defp refresh_and_store_token() do
    case refresh_access_token() do
      {:ok, new_token, expires_in} ->
        expires_at = :os.system_time(:seconds) + expires_in
        :dets.insert(@dets_table, {:access_token, new_token, expires_at})
        new_token

      {:error, reason} ->
        raise reason
    end
  end

  defp refresh_access_token() do
    client =
      Tesla.client([
        {Tesla.Middleware.Headers, [{"Content-Type", "application/x-www-form-urlencoded"}]},
        Tesla.Middleware.FormUrlencoded
      ])

    body = %{
      "client_id" => @client_id,
      "client_secret" => @client_secret,
      "refresh_token" => @refresh_token,
      "grant_type" => "refresh_token"
    }

    case Tesla.post(client, @token_url, body) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        response = Jason.decode!(body)
        {:ok, response["access_token"], response["expires_in"]}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error, "Failed to refresh token, Status: #{status}, Body: #{body}"}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
