defmodule Sdb.TasksTest do
  use ExUnit.Case, async: false

  alias Sdb.Tasks
  import Ecto.Changeset

  # Helper function to extract errors from changeset
  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_atom(key), key) |> to_string()
      end)
    end)
  end

  setup do
    # Use a unique temporary file for each test
    temp_file = System.tmp_dir!() |> Path.join("tasks_test_#{System.unique_integer()}.json")

    # Configure the test application to use our temp file
    Application.put_env(:sdb, :tasks_json_path, temp_file)

    # Start the GenServer for each test with a unique name
    name = :"TasksTest_#{System.unique_integer()}"
    {:ok, pid} = Tasks.start_link(name: name)

    on_exit(fn ->
      # Clean up: stop the GenServer and remove the temp file
      if Process.alive?(pid) do
        GenServer.stop(pid)
      end
      File.rm(temp_file)
    end)

    # Override the GenServer calls to use the test-specific name
    {:ok, %{temp_file: temp_file, name: name}}
  end

  describe "list_tasks/0" do
    test "returns empty list when no tasks exist", %{name: name} do
      assert Tasks.list_tasks(name) == []
    end

    test "returns all tasks when tasks exist", %{name: name} do
      {:ok, task1} = Tasks.create_task(%{"title" => "Task 1", "priority" => "high", "status" => "pending"}, name)
      {:ok, task2} = Tasks.create_task(%{"title" => "Task 2", "priority" => "low", "status" => "completed"}, name)

      tasks = Tasks.list_tasks(name)
      assert length(tasks) == 2
      assert Enum.any?(tasks, fn t -> t["id"] == task1["id"] end)
      assert Enum.any?(tasks, fn t -> t["id"] == task2["id"] end)
    end
  end

  describe "get_task/1" do
    test "returns nil when task not found" do
      assert Tasks.get_task("non-existent-id") == nil
    end

    test "returns task when found" do
      {:ok, created_task} = Tasks.create_task(%{"title" => "Test Task", "priority" => "medium", "status" => "pending"})

      retrieved_task = Tasks.get_task(created_task["id"])
      assert retrieved_task != nil
      assert retrieved_task["id"] == created_task["id"]
      assert retrieved_task["title"] == "Test Task"
    end
  end

  describe "create_task/1" do
    test "creates task with valid data" do
      attrs = %{
        "title" => "New Task",
        "description" => "Task description",
        "priority" => "high",
        "status" => "pending",
        "dueDate" => "2024-12-31"
      }

      {:ok, task} = Tasks.create_task(attrs)

      assert task["title"] == "New Task"
      assert task["description"] == "Task description"
      assert task["priority"] == "high"
      assert task["status"] == "pending"
      assert task["dueDate"] == "2024-12-31"
      assert task["id"] != nil
      assert task["createdAt"] != nil
      assert task["updatedAt"] != nil
    end

    test "creates task with only required fields" do
      attrs = %{
        "title" => "Minimal Task",
        "priority" => "low",
        "status" => "in_progress"
      }

      {:ok, task} = Tasks.create_task(attrs)

      assert task["title"] == "Minimal Task"
      assert task["priority"] == "low"
      assert task["status"] == "in_progress"
      refute task["description"]
      refute task["dueDate"]
      assert task["id"] != nil
    end

    test "returns error with invalid data" do
      attrs = %{
        "title" => "",
        "priority" => "invalid",
        "status" => "invalid"
      }

      {:error, changeset} = Tasks.create_task(attrs)
      refute changeset.valid?
      assert errors_on(changeset)[:title] == ["can't be blank"]
      assert errors_on(changeset)[:priority] == ["is invalid"]
      assert errors_on(changeset)[:status] == ["is invalid"]
    end

    test "persists task to file" do
      attrs = %{"title" => "Persistent Task", "priority" => "medium", "status" => "pending"}

      {:ok, _task} = Tasks.create_task(attrs)

      # Stop the GenServer and start a new one to test persistence
      GenServer.stop(Tasks)
      Tasks.start_link()

      tasks = Tasks.list_tasks()
      assert length(tasks) == 1
      assert hd(tasks)["title"] == "Persistent Task"
    end
  end

  describe "update_task/2" do
    test "updates existing task with valid data" do
      {:ok, created_task} = Tasks.create_task(%{
        "title" => "Original Task",
        "priority" => "low",
        "status" => "pending"
      })

      update_attrs = %{
        "title" => "Updated Task",
        "priority" => "high",
        "status" => "completed",
        "description" => "Added description"
      }

      {:ok, updated_task} = Tasks.update_task(created_task["id"], update_attrs)

      assert updated_task["id"] == created_task["id"]
      assert updated_task["title"] == "Updated Task"
      assert updated_task["priority"] == "high"
      assert updated_task["status"] == "completed"
      assert updated_task["description"] == "Added description"
      assert updated_task["createdAt"] == created_task["createdAt"]
      assert updated_task["updatedAt"] != created_task["updatedAt"]
    end

    test "returns error when task not found" do
      attrs = %{"title" => "Updated", "priority" => "high", "status" => "completed"}

      assert Tasks.update_task("non-existent-id", attrs) == {:error, :not_found}
    end

    test "returns error with invalid update data" do
      {:ok, task} = Tasks.create_task(%{
        "title" => "Test Task",
        "priority" => "low",
        "status" => "pending"
      })

      invalid_attrs = %{
        "priority" => "invalid",
        "status" => "invalid"
      }

      {:error, changeset} = Tasks.update_task(task["id"], invalid_attrs)
      refute changeset.valid?
      assert errors_on(changeset)[:priority] == ["is invalid"]
      assert errors_on(changeset)[:status] == ["is invalid"]
    end

    test "persists updates to file" do
      {:ok, created_task} = Tasks.create_task(%{
        "title" => "Original Task",
        "priority" => "low",
        "status" => "pending"
      })

      update_attrs = %{"title" => "Updated Task", "priority" => "high", "status" => "completed"}

      {:ok, _updated_task} = Tasks.update_task(created_task["id"], update_attrs)

      # Stop the GenServer and start a new one to test persistence
      GenServer.stop(Tasks)
      Tasks.start_link()

      tasks = Tasks.list_tasks()
      assert length(tasks) == 1
      task = hd(tasks)
      assert task["title"] == "Updated Task"
      assert task["priority"] == "high"
      assert task["status"] == "completed"
    end
  end

  describe "delete_task/1" do
    test "deletes existing task" do
      {:ok, created_task} = Tasks.create_task(%{
        "title" => "Task to Delete",
        "priority" => "low",
        "status" => "pending"
      })

      {:ok, deleted_task} = Tasks.delete_task(created_task["id"])

      assert deleted_task["id"] == created_task["id"]
      assert deleted_task["title"] == "Task to Delete"

      assert Tasks.get_task(created_task["id"]) == nil
      assert Tasks.list_tasks() == []
    end

    test "returns error when task not found" do
      assert Tasks.delete_task("non-existent-id") == {:error, :not_found}
    end

    test "persists deletion to file" do
      {:ok, task1} = Tasks.create_task(%{"title" => "Task 1", "priority" => "high", "status" => "pending"})
      {:ok, task2} = Tasks.create_task(%{"title" => "Task 2", "priority" => "low", "status" => "completed"})

      {:ok, _deleted_task} = Tasks.delete_task(task1["id"])

      # Stop the GenServer and start a new one to test persistence
      GenServer.stop(Tasks)
      Tasks.start_link()

      tasks = Tasks.list_tasks()
      assert length(tasks) == 1
      assert hd(tasks)["id"] == task2["id"]
    end
  end

  describe "file handling" do
    test "handles empty JSON file" do
      temp_file = System.tmp_dir!() |> Path.join("empty_tasks.json")
      File.write!(temp_file, "")

      Application.put_env(:sdb, :tasks_json_path, temp_file)
      GenServer.stop(Tasks)
      Tasks.start_link()

      assert Tasks.list_tasks() == []

      {:ok, task} = Tasks.create_task(%{
        "title" => "First Task",
        "priority" => "high",
        "status" => "pending"
      })

      assert task["title"] == "First Task"

      File.rm(temp_file)
    end

    test "handles malformed JSON file" do
      temp_file = System.tmp_dir!() |> Path.join("malformed_tasks.json")
      File.write!(temp_file, "{ invalid json }")

      Application.put_env(:sdb, :tasks_json_path, temp_file)
      GenServer.stop(Tasks)
      Tasks.start_link()

      # Should recover and start with empty tasks
      assert Tasks.list_tasks() == []

      File.rm(temp_file)
    end
  end
end