defmodule MangaDl.Client do
  require Logger
  use Supervisor
  @finch_name FinchWrapper
  def start_link(settings \\ %{}, opts \\ []) do
    Supervisor.start_link(__MODULE__, {:ok, settings}, opts)
  end

  def stop(reason \\ :normal, timeout \\ :infinity) do
    Supervisor.stop(@finch_name, reason, timeout)
  end

  @impl true
  def init({:ok, settings}) do
    children = [
      {
        Finch,
        name: @finch_name,
        pools:
          %{
            default: [size: System.schedulers_online()]
          }
          |> Map.merge(settings)
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def request(req, opts \\ []) do
    Finch.request(req, @finch_name, opts)
  end

  def stream(req, acc, fun, opts \\ []) do
    Finch.stream(req, @finch_name, acc, fun, opts)
  end
end
