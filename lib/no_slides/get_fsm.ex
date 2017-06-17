defmodule NoSlides.GetFsm do
  require Logger

  @timeout 10_000
  @n_val 3
  @n_readers 2

  def get(k) do
    req_id = mk_reqid()
    NoSlides.GetFsmSupervisor.start_get_fsm([req_id, self(), k])
    {:ok, req_id}
  end

  def start_link(req_id, from, k) do
    Logger.debug "Start GetFSM"
    {:ok, _} = :gen_fsm.start_link( __MODULE__, [req_id, from, k], [])
  end

  def init([req_id, from, k]) do
    {:ok, :prepare, %{req_id: req_id, from: from, key: k, readers: 0, results: []}, 0}
  end

  # Get info about on wich nodes write
  def prepare(:timeout, state) do
    idx = :riak_core_util.chash_key({"noslides", state.key})
    pref_list = :riak_core_apl.get_apl(idx, @n_val, NoSlides.Service)

    {:next_state, :execute, Map.put(state, :pref_list, pref_list), 0}
  end

  # Execute the call on all nodes ...
  def execute(:timeout, state) do
    :riak_core_vnode_master.command(
      state.pref_list,
      {:get, {state.req_id, state.key}},
      {:fsm, :undefined, self()},
      NoSlides.VNode_master)
    {:next_state, :consolidate, state, @timeout}
  end

  # check if we have all data then return it otherwise wait again ... (FOREVER?!??)
  # Why we don't check who resposnse??!
  def consolidate({:ok, _req_id, value}, state) do
    state = Map.put(state, :readers, state.readers + 1)
    state = Map.put(state, :results, [value | state.results])

    if state.readers == @n_readers do
      send(state.from, {state.req_id, :ok, Enum.uniq(state.results)})
      {:stop, :normal, state}
    else
      {:next_state, :consolidate, state, @timeout}
    end
  end

  def terminate(_reason, _name, _state) do
    :ok
  end

  #TODO - Change for remove warning
  defp mk_reqid do
    :erlang.phash2(:erlang.now())
  end

end
