defmodule Mailer.BroadwayEmailClient do
  use Broadway

  alias Broadway.Message
  alias Mailer.Email

  @rabbitmq_url Application.get_env(:mailer, Mailer.BroadwayEmailClient)[:rabbitmq_url]
  @rabbitmq_port Application.get_env(:mailer, Mailer.BroadwayEmailClient)[:rabbitmq_port]

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: EmailBroadway,
      producer: [
        module:
          {BroadwayRabbitMQ.Producer,
           queue: "email",
           connection: [
             host: @rabbitmq_url,
             port: @rabbitmq_port
           ],
           qos: [
             prefetch_count: 1
           ],
           on_failure: :reject},
        concurrency: 1
      ],
      processors: [
        default: [
          max_demand: 1,
          concurrency: 1
        ]
      ]
    )
  end

  @impl true
  def handle_message(_, message, _) do
    message
    |> IO.inspect(label: "email queue")

    data =
      case Jason.decode(message.data) do
        {:ok, msg} -> msg
        {:error, _} -> send_to_dlq(message.data)
      end

    resp =
      case data["cmd"] do
        "welcome" -> Email.welcome_email(data["params"]["send_to"])
      end

    case resp do
      {:ok, _} -> message
      {:error, _} -> determine_retry(message)
      {:error_fatal, _} -> send_to_dlq(message)
    end
  end

  defp send_to_dlq(message) do
    options = [host: @rabbitmq_url, port: @rabbitmq_port]
    {:ok, conn} = AMQP.Connection.open(options)
    {:ok, chan} = AMQP.Channel.open(conn)

    AMQP.Basic.publish(chan, "email_dlx", "dlq", message.data)
    message
  end

  defp determine_retry(message) do
    {_, _, %{delivery_tag: retry_count}} = message.acknowledger

    case retry_count > 5 do
      true -> send_to_dlq(message)
      false -> Broadway.Message.failed(message, :dlq)
    end
  end
end
