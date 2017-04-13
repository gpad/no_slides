defmodule NoSlides.CoverageFsm do
  require Logger
  @behaviour :riak_core_coverage_fsm

  @timeout 5000
  @n_val 1
  @vnode_coverage 1

  def start_link(req_id, from, what) do
    Logger.debug "[CoverageFsm.start_link] - req_id: #{inspect req_id} from: #{inspect from} what: #{inspect what}"
    :riak_core_coverage_fsm.start_link(
      __MODULE__,
      {:pid, req_id, from}, # from
      [req_id, from, what, @timeout]) #args
  end


  def init(_from, [req_id, from, what, timeout] = args) do
    Logger.debug ">>> [CoverageFsm.init]"
    {
      {what, req_id, from},
      :allup,
      @n_val,
      @vnode_coverage,
      NoSlides.Service,
      NoSlides.VNode_master,
      timeout,
      %{from: from, req_id: req_id, args: args}
    }
  end

  def process_results({_partition, value}, state) do
    Logger.debug ">>> [CoverageFsm.process_results]"
    {:done, Map.update(state, :res, [value], fn res -> [value | res] end)}
  end

  def finish(:clean, state) do
    Logger.debug ">>> [CoverageFsm.finish] -> #{inspect state.res}"
    send(state.from, {state.req_id, {:ok, Enum.concat(state.res)}})
    {:stop, :normal, state}
  end

  def finish({:error, reason}, state) do
    Logger.warn ">>> [CoverageFsm.finish] -> ERROR: #{inspect reason}"
    send(state.from, {state.req_id, {:error, reason}})
    {:stop, :normal, state}
  end

end
