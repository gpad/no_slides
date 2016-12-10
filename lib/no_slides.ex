defmodule NoSlides do
  use Application
  require Logger

  def start(_type, _args) do

    case NoSlides.Supervisor.start_link do
      {:ok, pid} ->
        :ok = :riak_core.register(vnode_module: NoSlides.VNode)
        :ok = :riak_core_node_watcher.service_up(NoSlides.Service, self())
        {:ok, pid}
      {:error, reason} ->
        Logger.error("Unable to start La Rocca supervisor because: #{inspect reason}")
    end

  end



end
