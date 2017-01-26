defmodule NoSlides.VNode do
  require Logger
  @behaviour :riak_core_vnode

  # This function is called to create vnode
  def start_vnode(partition) do
    # Logger.debug "[start_vnode] partition: #{inspect partition} - self: #{inspect self} ..."
    pid = :riak_core_vnode_master.get_vnode_pid(partition, __MODULE__)
    # Logger.debug "<< [start_vnode] return pid: #{inspect pid} for partition: #{inspect partition} - self: #{inspect self}"
    pid
  end

  def init([partition]) do
    Logger.debug("Init on partition: #{inspect partition} - self: #{inspect self}")
    # {:ok, %{partition: partition, data: %{node() => node()}}}
    {:ok, %{partition: partition, data: %{}}}
  end

  def handle_command({:ping, v}, sender, state) do
    Logger.debug("[ping received]: with value: #{inspect v} state: #{inspect state.partition} pid: #{inspect self}... ")
    # :timer.sleep(5000)
    Logger.debug("[ping received]: respond")
    {:reply, :pong, state}
  end

  def handle_command({:put, {k, v}}, sender, state) do
    Logger.debug("[put]: k: #{inspect k} v: #{inspect v}")
    new_state = Map.update(state, :data, %{}, fn data -> Map.put(data, k, v) end)
    {:reply, :pong, new_state}
  end

  def handle_command({:put, {req_id, k, v}}, sender, state) do
    Logger.debug("[ft_put]: req_id: #{inspect req_id} k: #{inspect k} v: #{inspect v} - sender: #{inspect sender}")
    new_state = Map.update(state, :data, %{}, fn data -> Map.put(data, k, v) end)
    {:reply, {:ok, req_id}, new_state}
  end

  def handle_command({:get, {k}}, sender, state) do
    Logger.debug("[get]: k: #{inspect k}")
    {:reply, Map.get(state.data, k, nil), state}
  end

  def handle_command({:get, {req_id, k}}, sender, state) do
    Logger.debug("[ft_get]: req_id: #{inspect req_id} k: #{inspect k} - sender: #{inspect sender}")
    {:reply, {:ok, req_id, Map.get(state.data, k, nil)}, state}
  end

  def handoff_starting(dest, state) do
    Logger.debug "[handoff_starting] dest: #{inspect dest} #{inspect state}"
    {true, state}
  end

  def handoff_cancelled(state) do
    Logger.debug "[handoff_cancelled] state: #{inspect state}"
    {:ok, state}
  end

  def handoff_finished(dest, state) do
    Logger.debug "[handoff_finished] state: #{inspect state}"
    {:ok, state}
  end

  require Record
  Record.defrecord :fold_reqv2, Record.extract(:riak_core_fold_req_v2, from_lib: "riak_core/include/riak_core_vnode.hrl")

  def handle_handoff_command(fold_req, _sender, state) do
    Logger.debug("[handle_handoff_command] #{inspect fold_req}")
    foldfun = fold_reqv2(fold_req, :foldfun)
    acc0 = fold_reqv2(fold_req, :acc0)
    Logger.debug("[handle_handoff_command] #{inspect foldfun}")
    Logger.debug("[handle_handoff_command] #{inspect acc0}")

    foldfun = fold_reqv2(fold_req, :foldfun)
    acc0 = fold_reqv2(fold_req, :acc0)

    acc_final = state.data |> Enum.reduce(acc0, fn {k, v}, acc ->
      foldfun.(k, v, acc)
    end)

    Logger.debug "[handle_handoff_command] acc_final: #{inspect acc_final}"

    {:reply, acc_final, state}
  end

  def is_empty(state) do
    empty = length(Map.keys(state.data)) == 0
    Logger.debug "is_empty ? #{empty}"
    {empty, state}
  end

  def terminate(reason, state) do
    Logger.debug("Terminate state: #{inspect state}")
    :ok
  end

  def delete(state) do
    {:ok, Map.put(state, :data, %{})}
  end

  def handle_handoff_data(bin_data, state) do
    Logger.debug("handoff_data #{inspect bin_data} - #{inspect state}")
    {k, v} = :erlang.binary_to_term(bin_data)
    new_state = Map.update(state, :data, %{}, fn data -> Map.put(data, k, v) end)
    {:reply, :ok, new_state}
  end

  def encode_handoff_item(k, v) do
    Logger.debug("encode_handoff_item #{inspect k} - #{inspect v}")
    :erlang.term_to_binary({k, v})
  end

  def handle_coverage(req, key_spaces, sender, state) do
    Logger.debug "handle_coverage VNODE self: #{inspect self} #{inspect state}"
    {:stop, :not_implemented, state}
  end

  def handle_exit(pid, reason, state) do
    Logger.debug "handle_exit VNODE self: #{inspect self} #{inspect state}"
    {:noreply, state}
  end

end
