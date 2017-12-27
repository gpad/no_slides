# NoSlides example application

Example application for the talk at [NoSlidesConf][0]. This application is a sample application with some functionalities available on riak_core.

## Erlang, Elixir, Rebar3 version
On this branch I start to use [asdf][4] and as you can find [here](./.tool-versions) I compile everything with:

```
erlang 19.3
elixir 1.4.2
```

I did a lot of problem to compile this because elixir now use rebar3 v 3.5.0 or greater, and it issue some problem especially with `cuttlefish` or other packages that want create and escript. Using an old version of rebar, the `3.2.0` for example everything works fine ...


There are some works on [riak_core][1] and [riak_core_ng][2] to move on Erlang 19.X, but when I wrote this docs it's not ready.

Clone the repository as usually, download the dependencies and compile the app in this way:

```shell
mix deps.get
mix compile
```

## How to start a single node
If you want run a single node you can execute in this way:

```shell
$ iex --name gpad@127.0.0.1 -S mix run
```
You can substitute `gpad` with the name that you prefer. You have to always run riak_core with full name using `--name` parameter.

## How to start multinode on same machine
In this repo it's possibile execute 3 nodes on the same machine. You can execute it in this way:

```shell
# this is node 1
MIX_ENV=gpad_1 iex --name gpad_1@127.0.0.1 -S mix run

# this is node 2
MIX_ENV=gpad_2 iex --name gpad_2@127.0.0.1 -S mix run

# this is node 3
MIX_ENV=gpad_3 iex --name gpad_3@127.0.0.1 -S mix run
```

If you want add more nodes you can check the file in `config` directory.

## Join/Leave node
When you run all the nodes they are running alone. If you want join two node together and create cluster you could go, for example, on console on node 2 and execute this command:

```elixir
iex(gpad_2@127.0.0.1)1>  :riak_core.join('gpad_1@127.0.0.1')
```
In this way node 2, called `gpad_2` is joined on node 1, called `gpad_1`. Now this two node are a cluster.

The same command could be executed on console of node 3:

```elixir
iex(gpad_3@127.0.0.1)1>  :riak_core.join('gpad_1@127.0.0.1')
```

When the cluster is stable you can try to put some data in it using the `put` command (see below) and then you can remove a node from the cluster with the `leave` command. Try it in this way:

```elixir
# removing node 2 from cluster
iex(gpad_2@127.0.0.1)1>  :riak_core.leave
```
How the cluster is composed is saved in disk so, if you stop and restart one or all nodes, they try to connect together, if you want destroy the cluster you can remove evry single node with `leave` command or deleted the various `ring_data_dir*`.


## Print ring status
After or before the join you can check the status of the ring. You can do this executing this command on elixir shell:

```elixir
iex(gpad_1@127.0.0.1)1> {:ok, ring} = :riak_core_ring_manager.get_my_ring
iex(gpad_1@127.0.0.1)1> :riak_core_ring.pretty_print(ring, [:legend])
```

## Functionalities
In this example it's now possible execute a `ping` command with default value of `1` but it's possible pass also a different value to have more chance to change the destination node.

```elixir
iex(gpad_1@127.0.0.1)1> NoSlides.Service.ping
iex(gpad_1@127.0.0.1)1> NoSlides.Service.ping(2)
#execute a lot of different ping
(1..20) |> Enum.each(fn v -> NoSlides.Service.ping(v) end)
```

It's also possible use this application as a simple KV memory store, in this way:

```elixir
# on node 1
iex(gpad_1@127.0.0.1)1> NoSlides.Service.put(:key, 42)
```
On node execute the command to store the value `42` associated with key `:key` and, it's possible get this value from another node, in this way:

```elixir
# on node 2
iex(gpad_2@127.0.0.1)1> NoSlides.Service.get(:key)
```

Depending on your configuration and how many nodes you are running, you can see some different node that respond to this requests. Try to get value before and after a join and a subsequent leave of a node.

## More infos...
I'm writing some post about the use of riak_core from Elixir, and you can find it [here][99].

## Credits
Thanks to:
- [basho](http://basho.com/) for creating the [library][1] and the [docs](http://basho.com/search/?q=riak_core).
- [Heinz N. Gies](https://twitter.com/heinz_gies) for creating [riak_core_ng][2] that can be used in [Elixir][3].
- [Ben Tyler](https://github.com/kanatohodets) for the inspiration talk at [ElixirConf.EU](http://www.elixirconf.eu/elixirconf2016/ben-tyler).
- [Mariano Guerra](https://twitter.com/warianoguerra) for this amazing [book](https://marianoguerra.github.io/little-riak-core-book/) about riak_core.
- [Ryan Zezeski](https://twitter.com/rzezeski) for his [blog](https://github.com/rzezeski/try-try-try) about riak_core.

[0]: http://www.noslidesconf.net/#schedule
[1]: https://github.com/basho/riak_core/
[2]: https://github.com/project-fifo/riak_core
[3]: https://hex.pm/packages/riak_core_ng
[4]: https://github.com/asdf-vm/asdf
[99]: https://medium.com/@gpad/
