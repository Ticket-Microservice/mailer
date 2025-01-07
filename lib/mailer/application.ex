defmodule Mailer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Mailer.GmailOAuth2.start_dets()

    children = [
      MailerWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:mailer, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Mailer.PubSub},
      # Start the Finch HTTP client for sending emails
      # {Finch, name: Mailer.Finch},
      # Start a worker by calling: Mailer.Worker.start_link(arg)
      # {Mailer.Worker, arg},
      # Start to serve requests, typically the last entry
      MailerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Mailer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MailerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
