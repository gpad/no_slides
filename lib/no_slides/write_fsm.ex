defmodule NoSlides.WriteFsm do
  require Logger

  @timeout 30_000
  @n_writers 2
  @n_val 3

  def write(k, v) do
    req_id = mk_reqid()
    NoSlides.WriteFsmSupervisor.start_write_fsm([req_id, self(), k, v])
    {:ok, req_id}
  end

  def start_link(req_id, from, k, v) do
    Logger.debug "Start WriteFSM"
    {:ok, _} = :gen_fsm.start_link( __MODULE__, [req_id, from, k, v], [])
  end

  def init([req_id, from, k, v]) do
    {:ok, :prepare, %{req_id: req_id, from: from, key: k, value: v, writers: 0}, 0}
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
      {:put, {state.req_id, state.key, state.value}},
      {:fsm, :undefined, self()},
      NoSlides.VNode_master)
    {:next_state, :consolidate, state, @timeout}
  end

  # check if we have all data then return it otherwise wait again ... (FOREVER?!??)
  # Why we don't check who resposnse??!
  def consolidate({:ok, _req_id}, state) do
    writers = state.writers + 1

    if writers == @n_writers do
      send(state.from, {state.req_id, :ok})
      {:stop, :normal, state}
    else
      {:next_state, :consolidate, Map.put(state, :writers, writers), @timeout}
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
