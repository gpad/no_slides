defmodule NoSlides.KeysCoverageFsm do
  require Logger
  @behaviour :riak_core_coverage_fsm

  @timeout 5000
  @n_val 3
  @vnode_coverage 3

  # start_link(ReqId, From, Request, Timeout) ->
  #     riak_core_coverage_fsm:start_link(?MODULE, {pid, ReqId, From},
  # [ReqId, From, Request, Timeout]).

  # -type from() :: {atom(), req_id(), pid()}.
  # -spec start_link(module(), from(), [term()]) ->
  #   {ok, pid()} | ignore | {error, term()}.
  def start_link(req_id, from, what) do
    Logger.debug "[KeysCoverageFsm.start_link] - req_id: #{inspect req_id} from: #{inspect from} what: #{inspect what}"
    :riak_core_coverage_fsm.start_link(
      __MODULE__,
      {:pid, req_id, from}, # from
      [req_id, from, what, @timeout]) #args
  end
  #
  # def init(from, args) do
  #   Logger.debug ">>> [KeysCoverageFsm.init] - from: #{inspect from} - args: #{inspect args}"
  #   [req_id, from, what, timeout] = args
  #   Logger.debug ">>> [KeysCoverageFsm.init] - ok"
  #   {{:xxx, req_id, from}, :all, @n_val, PrimaryVNodeCoverage,
  #    NoSlides.Service, NoSlides.VNode_master, timeout, %{from: from, args: args}}
  # end


  def init(_from, [req_id, from, what, timeout] = args) do
    Logger.debug ">>> [KeysCoverageFsm.init]\n\t- from: #{inspect from}\n\t- args: #{inspect args}"
    {{what, req_id, from}, :allup, @n_val, @vnode_coverage,
     NoSlides.Service, NoSlides.VNode_master, timeout, %{from: from, req_id: req_id, args: args}}
  end

  # TODO Aggiungi dei wait per tornare le chiavi o i valori e vediamo che succede ...

  def process_results({data, keys}, state) do
    Logger.debug ">>> [KeysCoverageFsm.process_results]\n\t- result: {#{inspect data}, #{inspect keys}}\n\t- state: #{inspect state}"
    {:done, Map.update(state, :res, keys, fn res -> [keys | res] end)}
  end

  def finish(:clean, state) do
    Logger.debug ">>> [KeysCoverageFsm.finish]\t\n- state: #{inspect state}"
    send(state.from, {state.req_id, {:ok, Enum.concat(state.res)}})
    {:stop, :normal, state}
  end

end
