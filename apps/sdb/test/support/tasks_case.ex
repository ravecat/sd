defmodule Sdb.TasksCase do
  @moduledoc """
  Test case template for Sdb.Tasks GenServer tests.

  Provides isolated test environment with:
  - Unique temporary JSON file for each test
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
    # Create unique temp file name for this test
    test_name = context.test |> to_string() |> String.replace(~r/[^\w]+/, "_")

    temp_file =
      Path.join([
        System.tmp_dir!(),
        "sdb_tasks_test_#{test_name}_#{System.unique_integer([:positive])}.json"
      ])

    # Initialize empty tasks file
    File.write!(temp_file, Jason.encode!(%{"tasks" => []}, pretty: true))

    # Create unique GenServer name for this test
    server_name = :"test_tasks_#{System.unique_integer([:positive])}"

    # Start GenServer with isolated file and name
    {:ok, pid} = Sdb.Tasks.start_link(name: server_name, path: temp_file)

    # Cleanup after test
    on_exit(fn ->
      if Process.alive?(pid), do: GenServer.stop(pid)
      File.rm(temp_file)
    end)

    {:ok, server: server_name, temp_file: temp_file, pid: pid}
  end

  @doc """
  Helper to insert a task directly into the GenServer.
  Returns the created task.
  """
  def insert_task(server, attrs \\ %{}) do
    default_attrs = %{
      "title" => "Test Task",
      "priority" => "medium",
      "status" => "pending"
    }

    {:ok, task} = Sdb.Tasks.create_task(Map.merge(default_attrs, attrs), server)
    task
  end
end
