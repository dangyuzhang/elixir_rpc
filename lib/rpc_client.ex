#  +----------------------------------------------------------------------
#  | Elixir Rpc [ WE CAN DO IT MORE SIMPLE ]
#  +----------------------------------------------------------------------
#  | Copyright (c) 2025 http://www.bytes.net.cn/ All rights reserved.
#  +----------------------------------------------------------------------
#  | Licensed ( http://www.apache.org/licenses/LICENSE-2.0 )
#  +---------------------------------------------------------------------
#  | Author: dangyuzhang <develop@bytes.net.cn>
#  +----------------------------------------------------------------------
defmodule Bytes.RpcClient do
  use GenServer

  require Logger
  alias Bytes.Rpc.{Meta, Request, Response}
  alias Bytes.Rpc.Route.Stub
  alias Bytes.Rpc.Json

  @name __MODULE__
  @reconnect_interval 3_000

  @default_config [
    port: 50051,
    host: "localhost",
    node: "default"
  ]

  ## Client API

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, name: @name)
  end

  def call(service, cmd, body), do: call(service, cmd, %{}, body)

  def call(service, cmd, header, body) do
    GenServer.call(@name, {:rpc_call, service, cmd, header, body}, 10_000)
  end

  def cast(service, cmd, body), do: cast(service, cmd, %{}, body)

  def cast(service, cmd, header, body) do
    GenServer.cast(@name, {:rpc_cast, service, cmd, header, body})
  end

  ## Server Callbacks

  def init(_arg) do
    config = Application.get_env(:elixir_rpc, __MODULE__, [])
    merged = Keyword.merge(@default_config, config)

    state = %{
      port: Keyword.fetch!(merged, :port),
      host: Keyword.fetch!(merged, :host),
      node: Keyword.fetch!(merged, :node),
      channel: nil
    }

    send(self(), :connect)
    {:ok, state}
  end

  def handle_call(_request, _from, %{channel: nil} = state) do
    Logger.warning("[RpcClient] Channel not connected.")
    {:reply, {:error, :not_connected}, state}
  end

  def handle_call(
        {:rpc_call, service, cmd, header, body},
        _from,
        %{channel: channel, node: node} = state
      ) do
    request = build_request(service, cmd, header, body, node)

    with {:ok, %Response{code: code, message: msg, data: data}} <-
           Stub.dispatcher(channel, request),
         {:ok, decoded_data} <- Json.decode(data) do
      {:reply, {:ok, %{code: code, message: msg, data: decoded_data}}, state}
    else
      {:error, reason} ->
        Logger.error("[RpcClient] RPC call failed: #{inspect(reason)}")
        {:reply, {:error, reason}, state}

      error ->
        Logger.error("[RpcClient] Unexpected error: #{inspect(error)}")
        {:reply, {:error, :unexpected}, state}
    end
  end

  def handle_cast(_msg, %{channel: nil} = state) do
    Logger.warning("[RpcClient] Cast dropped due to disconnected channel.")
    {:noreply, state}
  end

  def handle_cast(
        {:rpc_cast, service, cmd, header, body},
        %{channel: channel, node: node} = state
      ) do
    request = build_request(service, cmd, header, body, node)

    Task.start(fn ->
      _ = Stub.dispatcher(channel, request)
    end)

    {:noreply, state}
  end

  def handle_info(:connect, state) do
    case GRPC.Stub.connect("#{state.host}:#{state.port}") do
      {:ok, channel} ->
        Logger.info("[RpcClient] Connected to #{state.host}:#{state.port}")
        {:noreply, %{state | channel: channel}}

      {:error, reason} ->
        Logger.error(
          "[RpcClient] Connection failed: #{inspect(reason)}. Retrying in #{@reconnect_interval}ms"
        )

        Process.send_after(self(), :connect, @reconnect_interval)
        {:noreply, %{state | channel: nil}}
    end
  end

  defp build_request(service, cmd, header, body, node) do
    %Request{
      meta: %Meta{service: service, cmd: cmd, node: node},
      header: Json.encode(header),
      body: Json.encode(body)
    }
  end
end
