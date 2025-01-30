defmodule Mailer.BroadwayEmailClient do
  use Broadway

  alias Broadway.Message

  def start_link(_opts) do
    rabbitmq_url = Application.get_env(:mailer, Mailer.BroadwayEmailClient)[:rabbitmq_url]
    rabbitmq_port = Application.get_env(:mailer, Mailer.BroadwayEmailClient)[:rabbitmq_port]

    Broadway.start_link(__MODULE__,
      name: EmailBroadway,
      producer: [
        module: {BroadwayRabbitMQ.Producer,
          queue: "email",
          connection: [
            host: rabbitmq_url,
            port: rabbitmq_port
          ],
          qos: [
            prefetch_count: 1,
          ],
          on_failure: :reject
        },
        concurrency: 1,
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
    message = Broadway.Message.failed(message, :retry)
    |> IO.inspect(label: "nack")
    # Return :reject so RabbitMQ moves it to the DLX
    # {:noreply, [message], :reject}
    message
  end
end
