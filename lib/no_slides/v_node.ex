defmodule NoSlides.VNode do
  require Logger
  @behaviour :riak_core_vnode

  def start_vnode(partition) do
    :riak_core_vnode_master.get_vnode_pid(partition, __MODULE__)
  end

  def init([partition]) do
    Logger.debug("Init on partition: #{inspect partition} - self: #{inspect self()}")
    {:ok, %{partition: partition, data: %{}}}
  end

  def handle_command({:ping, v}, _sender, state) do
    Logger.debug("[ping received]: with value: #{inspect v} state: #{inspect state.partition} pid: #{inspect self()}... ")
    # :timer.sleep(5000)
    Logger.debug("[ping received]: respond")
    {:reply, :pong, state}
  end

  def handle_command({:put, {k, v}}, _sender, state) do
    Logger.debug("[put]: k: #{inspect k} v: #{inspect v}")
    new_state = Map.update(state, :data, %{}, fn data -> Map.put(data, k, v) end)
    {:reply, :ok, new_state}
  end

  def handle_command({:put, {req_id, k, v}}, sender, state) do
    Logger.debug("[ft_put]: req_id: #{inspect req_id} k: #{inspect k} v: #{inspect v} - sender: #{inspect sender}")
    new_state = Map.update(state, :data, %{}, fn data -> Map.put(data, k, v) end)
    {:reply, {:ok, req_id}, new_state}
  end

  def handle_command({:get, {k}}, _sender, state) do
    Logger.debug("[get]: k: #{inspect k}")
    {:reply, Map.get(state.data, k, nil), state}
  end

  def handle_command({:get, {req_id, k}}, sender, state) do
    Logger.debug("[ft_get]: req_id: #{inspect req_id} k: #{inspect k} - sender: #{inspect sender}")
    {:reply, {:ok, req_id, Map.get(state.data, k, nil)}, state}
  end

  def handoff_starting(dest, state) do
    Logger.debug "[handoff_starting] -\n\tdest: #{inspect dest}\n\tstate: #{inspect state}"
    {true, state}
  end

  def handoff_cancelled(state) do
    Logger.debug "[handoff_cancelled] state: #{inspect state}"
    {:ok, state}
  end

  def handoff_finished(_dest, state) do
    Logger.debug "[handoff_finished] state: #{inspect state}"
    {:ok, state}
  end

  require Record
  Record.defrecord :fold_req_v1, :riak_core_fold_req_v1, Record.extract(:riak_core_fold_req_v1, from_lib: "riak_core/include/riak_core_vnode.hrl")
  Record.defrecord :fold_req_v2, :riak_core_fold_req_v2, Record.extract(:riak_core_fold_req_v2, from_lib: "riak_core/include/riak_core_vnode.hrl")

  def handle_handoff_command(fold_req_v1() = fold_req, sender, state) do
    Logger.debug ">>>>> Handoff V1 <<<<<<"
    foldfun = fold_req_v1(fold_req, :foldfun)
    acc0 = fold_req_v1(fold_req, :acc0)
    handle_handoff_command(fold_req_v2(foldfun: foldfun, acc0: acc0), sender, state)
  end

  def handle_handoff_command(fold_req_v2() = fold_req, _sender, state) do
    Logger.debug ">>>>> Handoff V2 <<<<<<"
    foldfun = fold_req_v2(fold_req, :foldfun)
    acc0 = fold_req_v2(fold_req, :acc0)
    acc_final = state.data |> Enum.reduce(acc0, fn {k, v}, acc ->
      foldfun.(k, v, acc)
    end)
    {:reply, acc_final, state}
  end

  def handle_handoff_command(request, sender, state) do
    Logger.debug ">>> Handoff generic request <<<"
    Logger.debug "\t#{inspect request}"
    handle_command(request, sender, state)
  end

  def is_empty(state) do
    empty = length(Map.keys(state.data)) == 0
    Logger.debug "[is_empty] ? #{inspect empty}"
    {empty, state}
  end

  def terminate(reason, state) do
    Logger.debug("[terminate] reason: #{inspect reason} state: #{inspect state}")
    :ok
  end

  def delete(state) do
    Logger.debug "[delete] - #{inspect state}"
    {:ok, Map.put(state, :data, %{})}
  end

  def handle_handoff_data(bin_data, state) do
    Logger.debug("[handle_handoff_data] bin_data: #{inspect bin_data} - #{inspect state}")
    {k, v} = :erlang.binary_to_term(bin_data)
    new_state = Map.update(state, :data, %{}, fn data -> Map.put(data, k, v) end)
    {:reply, :ok, new_state}
  end

  def encode_handoff_item(k, v) do
    Logger.debug("[encode_handoff_item] #{inspect k} - #{inspect v}")
    :erlang.term_to_binary({k, v})
  end

  def handle_coverage({:keys, _, _} = req, _key_spaces, {_, ref_id, _} = sender, state) do
    Logger.debug "[handle_coverage] VNODE req: #{inspect req} sender: #{inspect sender}"
    {:reply, {ref_id, Map.keys(state.data)}, state}
  end

  def handle_coverage({:values, _, _} = req, _key_spaces, {_, ref_id, _} = sender, state) do
    Logger.debug "[handle_coverage] VNODE req: #{inspect req} sender: #{inspect sender}"
    {:reply, {ref_id, Map.values(state.data)}, state}
  end

  def handle_exit(pid, reason, state) do
    Logger.debug "[handle_exit] self: #{inspect self()} - pid: #{inspect pid} - reason: #{inspect reason} - state: #{inspect state}"
    {:noreply, state}
  end

end
