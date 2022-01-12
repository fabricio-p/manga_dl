defmodule MangaDl.ConnDict do
  def create() do
    Agent.start_link(fn() -> %{} end)
  end
  def get(dict_agent, host) do
  Agent.get(dict_agent, fn(dict) -> Map.get(dict, host) end)
  end
  def has(dict_agent, host) do
    Agent.get(dict_agent, fn(dict) -> Map.has_key?(dict, host) end)
  end
  def register(dict_agent, host, conn) do
    Agent.update(dict_agent, fn(dict) -> Map.put(dict, host, conn) end)
  end
  def close(dict_agent), do: Agent.stop(dict_agent)
end
