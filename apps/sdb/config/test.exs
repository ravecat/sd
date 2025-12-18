import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :sdb, SdbWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "3ewOHVMt17b/To4Mz50I7YtewsMPusBsO5O5LNfDoAoaNMu/pDny9Cv7dhe7O3x5",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

# Configure tasks JSON file path for tests
config :sdb, :tasks_json_path, "test/tasks.json"
