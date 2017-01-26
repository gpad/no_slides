# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :riak_core,
  node: 'gpad_4@127.0.0.1',
  web_port: 8498,
  handoff_port: 8499,
  ring_state_dir: 'ring_data_dir_4',
  platform_data_dir: 'data_4'

# config :lager,
#   handlers: [
#     lager_console_backend: :debug,
#   ]
