defmodule NoSlides.GetFsm do
  require Logger

  @timeout 10000

  def get(k) do
    req_id = mk_reqid()
    NoSlides.GetFsmSupervisor.start_get_fsm([req_id, self(), k])
    {:ok, req_id}
  end

  def start_link(req_id, from, k) do
    Logger.debug "Start GetFSM"
    :gen_fsm.start_link({:local, :get_fsm}, __MODULE__, [req_id, from, k], [])
  end

  def init([req_id, from, k]) do
    {:ok, :prepare, %{req_id: req_id, from: from, key: k, readers: 0, results: []}, 0}
  end

  # GEt info about on wich nodes write
  def prepare(:timeout, state) do
    idx = :riak_core_util.chash_key({"noslides", state.key})
    # pref_list = :riak_core_apl.get_primary_apl(idx, 1, NoSlides.Service)
    #TODO Verify the 3, is correct?!?
    pref_list = :riak_core_apl.get_apl(idx, 3, NoSlides.Service)

    {:next_state, :execute, Map.put(state, :pref_list, pref_list), 0}
  end

  # Execute the call on all nodes ...
  def execute(:timeout, state) do
    Logger.info("[EXECUTE] state: #{inspect state}")

    :riak_core_vnode_master.command(
      state.pref_list,
      {:get, {state.req_id, state.key}},
      {:fsm, :undefined, self()},
      NoSlides.VNode_master)

    Logger.info("[EXECUTE] next_state: consolidate")


    {:next_state, :consolidate, state, @timeout}
  end

  # check if we have all data then return it otherwise wait again ... (FOREVER?!??)
  # Why we don't check who resposnse??!
  def consolidate({:ok, req_id, value}, state) do
    Logger.info("[CONSOLIDATE] req_id: #{req_id} - value: #{inspect value}- state: #{inspect state}")
    state = Map.put(state, :readers, state.readers + 1)
    state = Map.put(state, :results, [value | state.results])

    if state.readers == 3 do
      send(state.from, {state.req_id, :ok, Enum.uniq(state.results)})
      {:stop, :normal, state}
    else
      {:next_state, :consolidate, state, @timeout}
    end
  end

  def terminate(reason, name, state) do
    :ok
  end

  #TODO - Copy from riak ...
  defp mk_reqid do
    :erlang.phash2(:erlang.now())
  end

end
