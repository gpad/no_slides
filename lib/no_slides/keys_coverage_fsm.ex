defmodule NoSlides.KeysCoverageFsm do
  require Logger
  @behaviour :riak_core_coverage_fsm

  @timeout 5000
  @n_val 3
  @vnode_coverage 3

  def start_link(req_id, from, what) do
    Logger.debug "[KeysCoverageFsm.start_link] - req_id: #{inspect req_id} from: #{inspect from} what: #{inspect what}"
    :riak_core_coverage_fsm.start_link(
      __MODULE__,
      {:pid, req_id, from}, # from
      [req_id, from, what, @timeout]) #args
  end


  def init(_from, [req_id, from, what, timeout] = args) do
    Logger.debug ">>> [KeysCoverageFsm.init]"
    {{what, req_id, from}, :allup, @n_val, @vnode_coverage,
     NoSlides.Service, NoSlides.VNode_master, timeout, %{from: from, req_id: req_id, args: args}}
  end

  def process_results({data, keys}, state) do
    Logger.debug ">>> [KeysCoverageFsm.process_results]"
    {:done, Map.update(state, :res, keys, fn res -> [keys | res] end)}
  end

  def finish(:clean, state) do
    Logger.debug ">>> [KeysCoverageFsm.finish]"
    send(state.from, {state.req_id, {:ok, Enum.concat(state.res)}})
    {:stop, :normal, state}
  end

end
