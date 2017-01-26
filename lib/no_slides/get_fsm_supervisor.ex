defmodule NoSlides.GetFsmSupervisor do
  use Supervisor

  def start_get_fsm(arg) do
    Supervisor.start_child(__MODULE__, arg)
  end

  def start_link() do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init(arg) do
    children = [
      worker(NoSlides.GetFsm, [], restart: :temporary)
    ]
    supervise(children, [strategy: :simple_one_for_one])
  end
end
