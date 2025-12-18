defmodule SdbWeb.TaskControllerTest do
  use SdbWeb.ConnCase, async: false

  alias Sdb.Tasks

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index/2" do
    test "lists all tasks", %{conn: conn} do
      tasks = [
        %{"id" => "task-1", "title" => "Task 1", "priority" => "high", "status" => "pending"},
        %{"id" => "task-2", "title" => "Task 2", "priority" => "low", "status" => "completed"}
      ]

      Repatch.patch(Tasks, :list_tasks, fn -> tasks end)

      conn = get(conn, ~p"/api/tasks")
      assert %{"tasks" => returned_tasks} = json_response(conn, 200)
      assert length(returned_tasks) == 2
    end

    test "returns empty list when no tasks exist", %{conn: conn} do
      Repatch.patch(Tasks, :list_tasks, fn -> [] end)

      conn = get(conn, ~p"/api/tasks")
      assert %{"tasks" => []} = json_response(conn, 200)
    end
  end

  describe "create/2" do
    test "creates task with valid data", %{conn: conn} do
      task_attrs = %{
        "title" => "New Task",
        "description" => "Task description",
        "priority" => "high",
        "status" => "pending",
        "dueDate" => "2024-12-31"
      }

      created_task =
        Map.merge(task_attrs, %{
          "id" => "generated-id",
          "createdAt" => "2024-12-18T10:00:00Z",
          "updatedAt" => "2024-12-18T10:00:00Z"
        })

      Repatch.patch(Tasks, :create_task, fn _attrs -> {:ok, created_task} end)

      conn = post(conn, ~p"/api/tasks", task: task_attrs)
      assert %{"task" => task} = json_response(conn, 201)

      assert task["title"] == "New Task"
      assert task["description"] == "Task description"
      assert task["priority"] == "high"
      assert task["status"] == "pending"
      assert task["dueDate"] == "2024-12-31"
      assert task["id"] == "generated-id"
      assert task["createdAt"] != nil
      assert task["updatedAt"] != nil
    end

    test "returns errors with invalid data", %{conn: conn} do
      invalid_attrs = %{
        "title" => "",
        "priority" => "invalid",
        "status" => "invalid"
      }

      # Create a changeset with errors
      changeset =
        {%{}, %{title: :string, priority: :string, status: :string}}
        |> Ecto.Changeset.cast(invalid_attrs, [:title, :priority, :status])
        |> Ecto.Changeset.validate_required([:title])
        |> Ecto.Changeset.add_error(:title, "can't be blank")
        |> Ecto.Changeset.add_error(:priority, "is invalid")
        |> Ecto.Changeset.add_error(:status, "is invalid")

      Repatch.patch(Tasks, :create_task, fn _attrs -> {:error, changeset} end)

      conn = post(conn, ~p"/api/tasks", task: invalid_attrs)
      assert %{"errors" => errors} = json_response(conn, 422)

      assert "can't be blank" in errors["title"]
      assert "is invalid" in errors["priority"]
      assert "is invalid" in errors["status"]
    end

    test "creates task with minimal valid data", %{conn: conn} do
      task_attrs = %{
        "title" => "Minimal Task",
        "priority" => "medium",
        "status" => "in_progress"
      }

      created_task =
        Map.merge(task_attrs, %{
          "id" => "minimal-id",
          "description" => nil,
          "dueDate" => nil,
          "createdAt" => "2024-12-18T10:00:00Z",
          "updatedAt" => "2024-12-18T10:00:00Z"
        })

      Repatch.patch(Tasks, :create_task, fn _attrs -> {:ok, created_task} end)

      conn = post(conn, ~p"/api/tasks", task: task_attrs)
      assert %{"task" => task} = json_response(conn, 201)

      assert task["title"] == "Minimal Task"
      assert task["priority"] == "medium"
      assert task["status"] == "in_progress"
    end
  end

  describe "show/2" do
    test "returns task when found", %{conn: conn} do
      task = %{
        "id" => "test-task-id",
        "title" => "Test Task",
        "priority" => "high",
        "status" => "pending",
        "createdAt" => "2024-12-18T10:00:00Z",
        "updatedAt" => "2024-12-18T10:00:00Z"
      }

      Repatch.patch(Tasks, :get_task, fn "test-task-id" -> task end)

      conn = get(conn, "/api/tasks/test-task-id")
      assert %{"task" => returned_task} = json_response(conn, 200)

      assert returned_task["id"] == "test-task-id"
      assert returned_task["title"] == "Test Task"
      assert returned_task["priority"] == "high"
      assert returned_task["status"] == "pending"
    end

    test "returns 404 when task not found", %{conn: conn} do
      Repatch.patch(Tasks, :get_task, fn _id -> nil end)

      conn = get(conn, ~p"/api/tasks/non-existent-id")
      assert %{"error" => "Task not found"} = json_response(conn, 404)
    end
  end

  describe "update/2" do
    test "updates task with valid data", %{conn: conn} do
      original_task = %{
        "id" => "task-to-update",
        "title" => "Original Task",
        "priority" => "low",
        "status" => "pending",
        "createdAt" => "2024-12-18T10:00:00Z",
        "updatedAt" => "2024-12-18T10:00:00Z"
      }

      updated_task = %{
        "id" => "task-to-update",
        "title" => "Updated Task",
        "priority" => "high",
        "status" => "completed",
        "description" => "Added description",
        "createdAt" => "2024-12-18T10:00:00Z",
        "updatedAt" => "2024-12-18T12:00:00Z"
      }

      Repatch.patch(Tasks, :update_task, fn "task-to-update", _attrs -> {:ok, updated_task} end)

      update_attrs = %{
        "title" => "Updated Task",
        "priority" => "high",
        "status" => "completed",
        "description" => "Added description"
      }

      conn = put(conn, ~p"/api/tasks/task-to-update", task: update_attrs)
      assert %{"task" => task} = json_response(conn, 200)

      assert task["id"] == "task-to-update"
      assert task["title"] == "Updated Task"
      assert task["priority"] == "high"
      assert task["status"] == "completed"
      assert task["description"] == "Added description"
      assert task["createdAt"] == original_task["createdAt"]
      assert task["updatedAt"] != original_task["updatedAt"]
    end

    test "returns 404 when task not found", %{conn: conn} do
      Repatch.patch(Tasks, :update_task, fn _id, _attrs -> {:error, :not_found} end)

      update_attrs = %{"title" => "Updated", "priority" => "high", "status" => "completed"}

      conn = put(conn, ~p"/api/tasks/non-existent-id", task: update_attrs)
      assert %{"error" => "Task not found"} = json_response(conn, 404)
    end

    test "returns errors with invalid update data", %{conn: conn} do
      changeset =
        {%{}, %{priority: :string, status: :string}}
        |> Ecto.Changeset.cast(%{}, [:priority, :status])
        |> Ecto.Changeset.add_error(:priority, "is invalid")
        |> Ecto.Changeset.add_error(:status, "is invalid")

      Repatch.patch(Tasks, :update_task, fn _id, _attrs -> {:error, changeset} end)

      invalid_attrs = %{
        "priority" => "invalid",
        "status" => "invalid"
      }

      conn = put(conn, ~p"/api/tasks/task-id", task: invalid_attrs)
      assert %{"errors" => errors} = json_response(conn, 422)

      assert "is invalid" in errors["priority"]
      assert "is invalid" in errors["status"]
    end
  end

  describe "delete/2" do
    test "deletes existing task", %{conn: conn} do
      deleted_task = %{
        "id" => "task-to-delete",
        "title" => "Task to Delete",
        "priority" => "low",
        "status" => "pending"
      }

      Repatch.patch(Tasks, :delete_task, fn "task-to-delete" -> {:ok, deleted_task} end)

      conn = delete(conn, ~p"/api/tasks/task-to-delete")
      assert response(conn, 204)
    end

    test "returns 404 when task not found", %{conn: conn} do
      Repatch.patch(Tasks, :delete_task, fn _id -> {:error, :not_found} end)

      conn = delete(conn, ~p"/api/tasks/non-existent-id")
      assert %{"error" => "Task not found"} = json_response(conn, 404)
    end

    test "returns empty response on successful deletion", %{conn: conn} do
      deleted_task = %{"id" => "task-to-delete", "title" => "Task to Delete"}

      Repatch.patch(Tasks, :delete_task, fn _id -> {:ok, deleted_task} end)

      conn = delete(conn, ~p"/api/tasks/task-to-delete")
      assert response(conn, 204)
      assert response(conn, 204) == ""
    end
  end

  describe "API endpoints behavior" do
    test "requires JSON accept header", %{conn: conn} do
      task_attrs = %{
        "title" => "Test Task",
        "priority" => "high",
        "status" => "pending"
      }

      created_task =
        Map.merge(task_attrs, %{
          "id" => "test-id",
          "createdAt" => "2024-12-18T10:00:00Z",
          "updatedAt" => "2024-12-18T10:00:00Z"
        })

      Repatch.patch(Tasks, :create_task, fn _attrs -> {:ok, created_task} end)

      conn = post(conn, ~p"/api/tasks", task: task_attrs)
      assert %{"task" => _task} = json_response(conn, 201)
    end

    test "handles malformed JSON gracefully", %{conn: conn} do
      assert_raise Plug.Parsers.ParseError, fn ->
        conn
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/tasks", "invalid json")
      end
    end
  end
end
