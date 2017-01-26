defmodule NoSlides.WriteFsm do
  require Logger

  @timeout 10000

  def write(k, v) do
    req_id = mk_reqid()
    NoSlides.FsmSupervisor.start_write_fsm([req_id, self(), k, v])
    {:ok, req_id}
  end

  def start_link(req_id, from, k, v) do
    Logger.debug "Start WriteFSM"
    :gen_fsm.start_link({:local, :write_fsm}, __MODULE__, [req_id, from, k, v], [])
  end

  def init([req_id, from, k, v]) do
    {:ok, :prepare, %{req_id: req_id, from: from, key: k, value: v, writers: 0}, 0}
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
      {:put, {state.req_id, state.key, state.value}},
      {:fsm, :undefined, self()},
      NoSlides.VNode_master)

    Logger.info("[EXECUTE] next_state: consolidate")


    {:next_state, :consolidate, state, @timeout}
  end

  # check if we have all data then return it otherwise wait again ... (FOREVER?!??)
  # Why we don't check who resposnse??!
  def consolidate({:ok, req_id}, state) do
    Logger.info("[CONSOLIDATE] req_id: #{req_id} - state: #{inspect state}")
    writers = state.writers + 1

    if writers == 3 do
      send(state.from, {state.req_id, :ok})
      {:stop, :normal, state}
    else
      {:next_state, :consolidate, Map.put(state, :writers, writers), @timeout}
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
