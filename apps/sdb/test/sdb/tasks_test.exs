defmodule Sdb.TasksTest do
  use Sdb.TasksCase, async: false

  describe "list_tasks/1" do
    test "returns empty list when no tasks exist", %{server: server} do
      assert Tasks.list_tasks(server) == []
    end

    test "returns all tasks", %{server: server} do
      task1 = insert_task(server, %{"title" => "Task 1"})
      task2 = insert_task(server, %{"title" => "Task 2"})

      tasks = Tasks.list_tasks(server)

      assert length(tasks) == 2
      assert Enum.any?(tasks, fn t -> t["id"] == task1["id"] end)
      assert Enum.any?(tasks, fn t -> t["id"] == task2["id"] end)
    end
  end

  describe "get_task/2" do
    test "returns task by id", %{server: server} do
      task = insert_task(server, %{"title" => "Find me"})

      found_task = Tasks.get_task(task["id"], server)

      assert found_task["id"] == task["id"]
      assert found_task["title"] == "Find me"
    end

    test "returns nil for non-existent id", %{server: server} do
      assert Tasks.get_task("non-existent-id", server) == nil
    end
  end

  describe "create_task/2" do
    test "creates task with valid attributes", %{server: server} do
      attrs = %{
        "title" => "New Task",
        "priority" => "high",
        "status" => "pending",
        "description" => "Task description",
        "dueDate" => "2024-12-31"
      }

      assert {:ok, task} = Tasks.create_task(attrs, server)
      assert task["title"] == "New Task"
      assert task["priority"] == "high"
      assert task["status"] == "pending"
      assert task["description"] == "Task description"
      assert task["dueDate"] == "2024-12-31"
      assert is_binary(task["id"])
      assert is_binary(task["createdAt"])
      assert is_binary(task["updatedAt"])
    end

    test "creates task with only required fields", %{server: server} do
      attrs = %{
        "title" => "Minimal Task",
        "priority" => "low",
        "status" => "in_progress"
      }

      assert {:ok, task} = Tasks.create_task(attrs, server)
      assert task["title"] == "Minimal Task"
      assert task["priority"] == "low"
      assert task["status"] == "in_progress"
      assert task["description"] == nil
      assert task["dueDate"] == nil
    end

    test "returns error changeset for missing required fields", %{server: server} do
      attrs = %{"description" => "Only description"}

      assert {:error, changeset} = Tasks.create_task(attrs, server)
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "can't be blank" in errors[:title]
      assert "can't be blank" in errors[:priority]
      assert "can't be blank" in errors[:status]
    end

    test "returns error for invalid priority", %{server: server} do
      attrs = %{
        "title" => "Task",
        "priority" => "urgent",
        "status" => "pending"
      }

      assert {:error, changeset} = Tasks.create_task(attrs, server)
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset)[:priority]
    end

    test "returns error for invalid status", %{server: server} do
      attrs = %{
        "title" => "Task",
        "priority" => "high",
        "status" => "done"
      }

      assert {:error, changeset} = Tasks.create_task(attrs, server)
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset)[:status]
    end

    test "persists task to file", %{server: server, temp_file: temp_file} do
      attrs = %{
        "title" => "Persisted Task",
        "priority" => "medium",
        "status" => "pending"
      }

      {:ok, task} = Tasks.create_task(attrs, server)

      # Read file directly to verify persistence
      {:ok, content} = File.read(temp_file)
      {:ok, %{"tasks" => tasks}} = Jason.decode(content)

      assert length(tasks) == 1
      assert hd(tasks)["id"] == task["id"]
      assert hd(tasks)["title"] == "Persisted Task"
    end
  end

  describe "update_task/3" do
    test "updates task with valid attributes", %{server: server} do
      task = insert_task(server, %{"title" => "Original", "priority" => "low"})
      original_id = task["id"]
      original_created_at = task["createdAt"]

      attrs = %{"title" => "Updated", "priority" => "high"}

      assert {:ok, updated_task} = Tasks.update_task(original_id, attrs, server)
      assert updated_task["id"] == original_id
      assert updated_task["title"] == "Updated"
      assert updated_task["priority"] == "high"
      assert updated_task["createdAt"] == original_created_at
      assert updated_task["updatedAt"] != task["updatedAt"]
    end

    test "returns error for non-existent task", %{server: server} do
      attrs = %{"title" => "Won't work"}

      assert {:error, :not_found} = Tasks.update_task("non-existent-id", attrs, server)
    end

    test "returns error for invalid attributes", %{server: server} do
      task = insert_task(server)

      attrs = %{"priority" => "invalid_priority"}

      assert {:error, changeset} = Tasks.update_task(task["id"], attrs, server)
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset)[:priority]
    end

    test "persists update to file", %{server: server, temp_file: temp_file} do
      task = insert_task(server, %{"title" => "Before Update"})

      {:ok, _updated} = Tasks.update_task(task["id"], %{"title" => "After Update"}, server)

      # Read file directly
      {:ok, content} = File.read(temp_file)
      {:ok, %{"tasks" => tasks}} = Jason.decode(content)

      assert hd(tasks)["title"] == "After Update"
    end
  end

  describe "delete_task/2" do
    test "deletes existing task", %{server: server} do
      task = insert_task(server)

      assert {:ok, deleted_task} = Tasks.delete_task(task["id"], server)
      assert deleted_task["id"] == task["id"]

      # Verify task is gone
      assert Tasks.get_task(task["id"], server) == nil
      assert Tasks.list_tasks(server) == []
    end

    test "returns error for non-existent task", %{server: server} do
      assert {:error, :not_found} = Tasks.delete_task("non-existent-id", server)
    end

    test "persists deletion to file", %{server: server, temp_file: temp_file} do
      task = insert_task(server)

      {:ok, _deleted} = Tasks.delete_task(task["id"], server)

      # Read file directly
      {:ok, content} = File.read(temp_file)
      {:ok, %{"tasks" => tasks}} = Jason.decode(content)

      assert tasks == []
    end
  end

  describe "init/1" do
    test "creates file if it doesn't exist" do
      temp_dir = System.tmp_dir!()
      new_file = Path.join(temp_dir, "new_tasks_#{System.unique_integer([:positive])}.json")
      server_name = :"init_test_#{System.unique_integer([:positive])}"

      # Ensure file doesn't exist
      File.rm(new_file)
      refute File.exists?(new_file)

      # Start GenServer
      {:ok, pid} = Tasks.start_link(name: server_name, path: new_file)

      # File should now exist
      assert File.exists?(new_file)
      {:ok, content} = File.read(new_file)
      assert {:ok, %{"tasks" => []}} = Jason.decode(content)

      # Cleanup
      GenServer.stop(pid)
      File.rm(new_file)
    end

    test "loads existing tasks from file" do
      temp_dir = System.tmp_dir!()
      existing_file = Path.join(temp_dir, "existing_tasks_#{System.unique_integer([:positive])}.json")
      server_name = :"load_test_#{System.unique_integer([:positive])}"

      # Create file with existing task
      existing_task = %{
        "id" => "existing-id",
        "title" => "Existing Task",
        "priority" => "high",
        "status" => "pending",
        "createdAt" => "2024-01-01T00:00:00Z",
        "updatedAt" => "2024-01-01T00:00:00Z"
      }

      File.write!(existing_file, Jason.encode!(%{"tasks" => [existing_task]}, pretty: true))

      # Start GenServer
      {:ok, pid} = Tasks.start_link(name: server_name, path: existing_file)

      # Verify task was loaded
      tasks = Tasks.list_tasks(server_name)
      assert length(tasks) == 1
      assert hd(tasks)["id"] == "existing-id"
      assert hd(tasks)["title"] == "Existing Task"

      # Cleanup
      GenServer.stop(pid)
      File.rm(existing_file)
    end

    test "handles corrupted JSON file gracefully" do
      temp_dir = System.tmp_dir!()
      corrupted_file = Path.join(temp_dir, "corrupted_#{System.unique_integer([:positive])}.json")
      server_name = :"corrupted_test_#{System.unique_integer([:positive])}"

      # Create corrupted file
      File.write!(corrupted_file, "not valid json {{{")

      # Start GenServer - should handle gracefully
      {:ok, pid} = Tasks.start_link(name: server_name, path: corrupted_file)

      # Should have empty tasks
      assert Tasks.list_tasks(server_name) == []

      # Cleanup
      GenServer.stop(pid)
      File.rm(corrupted_file)
    end
  end

  # Helper to extract errors from changeset
  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_atom(key), key) |> to_string()
      end)
    end)
  end
end
