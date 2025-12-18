defmodule Sdb.TasksCase do
  @moduledoc """
  Test case template for Sdb.Tasks GenServer tests.

  Provides isolated test environment with:
  - Unique temporary directory for each test
  - Unique user_id for isolation
  - Unique GenServer name to avoid conflicts
  - Automatic cleanup after each test
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Sdb.Tasks
      alias Sdb.Tasks.Task

      import Sdb.TasksCase
    end
  end

  setup context do
    # Create unique temp directory for this test
    test_name = context.test |> to_string() |> String.replace(~r/[^\w]+/, "_")

    temp_dir =
      Path.join([
        System.tmp_dir!(),
        "sdb_tasks_test_#{test_name}_#{System.unique_integer([:positive])}"
      ])

    # Ensure directory exists
    File.mkdir_p!(temp_dir)

    # Generate unique user_id for this test
    user_id = Ecto.UUID.generate()

    # Create unique GenServer name for this test
    server_name = :"test_tasks_#{System.unique_integer([:positive])}"

    # Start GenServer with isolated directory and name
    {:ok, pid} = Sdb.Tasks.start_link(name: server_name, base_dir: temp_dir)

    # Cleanup after test
    on_exit(fn ->
      if Process.alive?(pid), do: GenServer.stop(pid)
      File.rm_rf(temp_dir)
    end)

    {:ok, server: server_name, temp_dir: temp_dir, user_id: user_id, pid: pid}
  end

  @doc """
  Helper to insert a task directly into the GenServer.
  Returns the created task.
  """
  def insert_task(server, user_id, attrs \\ %{}) do
    default_attrs = %{
      "title" => "Test Task",
      "priority" => "medium",
      "status" => "pending"
    }

    {:ok, task} = Sdb.Tasks.create_task(user_id, Map.merge(default_attrs, attrs), server)
    task
  end

  @doc """
  Get the file path for a specific user's tasks.
  """
  def user_file_path(temp_dir, user_id) do
    Path.join(temp_dir, "#{user_id}.json")
  end
end
