defmodule GuardianRedis.Redix do
  @moduledoc """
    Redix module
  """
  @default_redis_url "redis://127.0.0.1:6379"
  @default_redis_pool_size 1

  @doc """
  Specs for the Redix connections.
  """
  def child_spec(_args) do
    children =
      for index <- 0..(pool_size() - 1) do
        Supervisor.child_spec(
          {Redix, {redis_url(), name: :"redix_#{index}"}},
          id: {Redix, index}
        )
      end

    %{
      id: RedixSupervisor,
      type: :supervisor,
      start: {Supervisor, :start_link, [children, [strategy: :one_for_one]]}
    }
  end

  @doc """
  Redis commands execution via pool of Redix workers
  command_params - List of String commands, e.g. ["GET", "redis_key"]

  ## Examples

      iex> GuardianRedis.Redix.command(["SET", "key", "value"])
      {:ok, "OK"}
      iex> GuardianRedis.Redix.command(["GET", "key"])
      {:ok, "value"}
  """
  @spec command(command_params :: List.t()) ::
          {:ok, Redix.Protocol.redis_value()}
          | {:error, atom() | Redix.Error.t() | Redix.ConnectionError.t()}
  def command(command_params) do
    Redix.command(:"redix_#{random_index()}", command_params)
  end

  defp redis_url do
    redis_config()[:url] || @default_redis_url
  end

  defp pool_size do
    "#{redis_config()[:pool_size] || @default_redis_pool_size}" |> String.to_integer()
  end

  defp redis_config do
    Application.get_env(:guardian_redis, :redis)
  end

  defp random_index() do
    Enum.random(0..(pool_size() - 1))
  end
end
