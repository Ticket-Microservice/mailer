defmodule Mailer.RabbitmqSetup do
  @moduledoc false
  alias AMQP.{Connection, Channel, Queue, Exchange}

  def setup_queues do
    rabbitmq_url = Application.get_env(:mailer, Mailer.BroadwayEmailClient)[:rabbitmq_url]
    rabbitmq_port = Application.get_env(:mailer, Mailer.BroadwayEmailClient)[:rabbitmq_port]

    options = [host: rabbitmq_url, port: rabbitmq_port]
    {:ok, conn} = Connection.open(options)
    {:ok, chan} = Channel.open(conn)

    # Declare the Dead Letter Exchange (DLX)
    Exchange.declare(chan, "email_dlx", :direct, durable: true)

    # Declare the main queue with a DLX
    Queue.declare(chan, "email",
      durable: true,
      arguments: [
        {"x-dead-letter-exchange", "email_dlx"},  # Send failed messages to DLX
        {"x-dead-letter-routing-key", "retry"}   # Route to Dead Letter Queue
      ]
    )

    Queue.declare(chan, "email_retry",
      durable: true,
      arguments: [
        {"x-message-ttl", 5000},  # Retry delay (5 seconds)
        {"x-dead-letter-exchange", ""},  # Move back to the main queue
        {"x-dead-letter-routing-key", "email"}
      ]
    )

    # Declare the Dead Letter Queue (DLQ)
    Queue.declare(chan, "email_dlq", durable: true)

    Queue.bind(chan, "email_retry", "email_dlx", routing_key: "retry")
    Queue.bind(chan, "email_dlq", "email_dlx", routing_key: "dlq")
    # Bind DLQ to DLX

    # Close the connection
    Channel.close(chan)
    Connection.close(conn)

    :ok
  end
end
