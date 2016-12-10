# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :riak_core,
  node: 'gpad_1@127.0.0.1',
  web_port: 8198,
  handoff_port: 8199,
  ring_state_dir: 'ring_data_dir_1',
  platform_data_dir: 'data_1'

  # config :lager,
  #   handlers: [
  #     lager_console_backend: :debug,
  #   ]
