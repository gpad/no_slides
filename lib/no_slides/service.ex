defmodule NoSlides.Service do

  def ping(v\\1) do
    idx = :riak_core_util.chash_key({"noslides", "ping#{v}"})
    pref_list = :riak_core_apl.get_primary_apl(idx, 1, NoSlides.Service)

    [{index_node, _type}] = pref_list

    :riak_core_vnode_master.sync_command(index_node, {:ping, v}, NoSlides.VNode_master)
  end

  def ping_spawn(v\\1) do
    idx = :riak_core_util.chash_key({"noslides", "ping#{v}"})
    pref_list = :riak_core_apl.get_primary_apl(idx, 1, NoSlides.Service)

    [{index_node, _type}] = pref_list

    :riak_core_vnode_master.sync_spawn_command(index_node, {:ping, v}, NoSlides.VNode_master)
  end

  def async_ping(v\\1) do
    idx = :riak_core_util.chash_key({"noslides", "ping#{v}"})
    pref_list = :riak_core_apl.get_primary_apl(idx, 1, NoSlides.Service)

    [{index_node, _type}] = pref_list

    :riak_core_vnode_master.command(index_node, {:ping, v}, NoSlides.VNode_master)
  end

  def put(k, v) do
    idx = :riak_core_util.chash_key({"noslides", k})
    pref_list = :riak_core_apl.get_primary_apl(idx, 1, NoSlides.Service)

    [{index_node, _type}] = pref_list

    :riak_core_vnode_master.command(index_node, {:put, {k, v}}, NoSlides.VNode_master)
  end

  def get(k) do
    idx = :riak_core_util.chash_key({"noslides", k})
    pref_list = :riak_core_apl.get_primary_apl(idx, 1, NoSlides.Service)

    [{index_node, _type}] = pref_list

    :riak_core_vnode_master.sync_command(index_node, {:get, k}, NoSlides.VNode_master)
  end

  def ring_status() do
    {:ok, ring} = :riak_core_ring_manager.get_my_ring
    :riak_core_ring.pretty_print(ring, [:legend])
  end

  def keys do
    req_id = NoSlides.KeysCoverageFsmSupervisor.start_keys_fsm(:keys)
    receive do
      {^req_id, {:ok, keys}} ->
        keys
      {^req_id, {:error, reason}} ->
        {:error, reason}
    after 5000 ->
      {:error, :timeout}
    end
  end

  def values do
    req_id = NoSlides.KeysCoverageFsmSupervisor.start_keys_fsm(:values)
    receive do
      {^req_id, {:ok, keys}} ->
        keys
      {^req_id, {:error, reason}} ->
        {:error, reason}
    after 5000 ->
      {:error, :timeout}
    end
  end

end
