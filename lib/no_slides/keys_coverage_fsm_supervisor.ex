defmodule NoSlides.CoverageFsmSupervisor do
  use Supervisor
  require Logger

  def start_fsm(what) do
    req_id = mk_req_id()
    {:ok, _} = Supervisor.start_child(__MODULE__, [req_id, self(), what])
    req_id
  end

  def start_link() do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init(_args) do
    children = [
      worker(NoSlides.CoverageFsm, [], restart: :temporary)
    ]
    supervise(children, strategy: :simple_one_for_one, max_restarts: 5, max_seconds: 10)
  end

  defp mk_req_id() do
    # :erlang.phash2(:time_compat.monotonic_time())
    :erlang.phash2(:erlang.now())
  end

end
