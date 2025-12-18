defmodule SdbWeb.TaskControllerTest do
  use SdbWeb.ConnCase, async: true

  alias Sdb.Tasks

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index/2" do
    test "lists all tasks", %{conn: conn} do
      # Create some test tasks
      {:ok, _task1} = Tasks.create_task(%{
        "title" => "Task 1",
        "priority" => "high",
        "status" => "pending"
      })

      {:ok, _task2} = Tasks.create_task(%{
        "title" => "Task 2",
        "priority" => "low",
        "status" => "completed"
      })

      conn = get(conn, ~p"/api/tasks")
      assert %{"tasks" => tasks} = json_response(conn, 200)
      assert length(tasks) == 2
    end

    test "returns empty list when no tasks exist", %{conn: conn} do
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

      conn = post(conn, ~p"/api/tasks", task: task_attrs)
      assert %{"task" => task} = json_response(conn, 201)

      assert task["title"] == "New Task"
      assert task["description"] == "Task description"
      assert task["priority"] == "high"
      assert task["status"] == "pending"
      assert task["dueDate"] == "2024-12-31"
      assert task["id"] != nil
      assert task["createdAt"] != nil
      assert task["updatedAt"] != nil
    end

    test "returns errors with invalid data", %{conn: conn} do
      invalid_attrs = %{
        "title" => "",
        "priority" => "invalid",
        "status" => "invalid"
      }

      conn = post(conn, ~p"/api/tasks", task: invalid_attrs)
      assert %{"errors" => errors} = json_response(conn, 422)

      assert errors["title"] == ["can't be blank"]
      assert errors["priority"] == ["is invalid"]
      assert errors["status"] == ["is invalid"]
    end

    test "creates task with minimal valid data", %{conn: conn} do
      task_attrs = %{
        "title" => "Minimal Task",
        "priority" => "medium",
        "status" => "in_progress"
      }

      conn = post(conn, ~p"/api/tasks", task: task_attrs)
      assert %{"task" => task} = json_response(conn, 201)

      assert task["title"] == "Minimal Task"
      assert task["priority"] == "medium"
      assert task["status"] == "in_progress"
    end
  end

  describe "show/2" do
    test "returns task when found", %{conn: conn} do
      {:ok, created_task} = Tasks.create_task(%{
        "title" => "Test Task",
        "priority" => "high",
        "status" => "pending"
      })

      conn = get(conn, ~p"/api/tasks/#{created_task["id"]}")
      assert %{"task" => task} = json_response(conn, 200)

      assert task["id"] == created_task["id"]
      assert task["title"] == "Test Task"
      assert task["priority"] == "high"
      assert task["status"] == "pending"
    end

    test "returns 404 when task not found", %{conn: conn} do
      conn = get(conn, ~p"/api/tasks/non-existent-id")
      assert %{"error" => "Task not found"} = json_response(conn, 404)
    end
  end

  describe "update/2" do
    test "updates task with valid data", %{conn: conn} do
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

      conn = put(conn, ~p"/api/tasks/#{created_task["id"]}", task: update_attrs)
      assert %{"task" => task} = json_response(conn, 200)

      assert task["id"] == created_task["id"]
      assert task["title"] == "Updated Task"
      assert task["priority"] == "high"
      assert task["status"] == "completed"
      assert task["description"] == "Added description"
      assert task["createdAt"] == created_task["createdAt"]
      assert task["updatedAt"] != created_task["updatedAt"]
    end

    test "returns 404 when task not found", %{conn: conn} do
      update_attrs = %{"title" => "Updated", "priority" => "high", "status" => "completed"}

      conn = put(conn, ~p"/api/tasks/non-existent-id", task: update_attrs)
      assert %{"error" => "Task not found"} = json_response(conn, 404)
    end

    test "returns errors with invalid update data", %{conn: conn} do
      {:ok, task} = Tasks.create_task(%{
        "title" => "Test Task",
        "priority" => "low",
        "status" => "pending"
      })

      invalid_attrs = %{
        "priority" => "invalid",
        "status" => "invalid"
      }

      conn = put(conn, ~p"/api/tasks/#{task["id"]}", task: invalid_attrs)
      assert %{"errors" => errors} = json_response(conn, 422)

      assert errors["priority"] == ["is invalid"]
      assert errors["status"] == ["is invalid"]
    end
  end

  describe "delete/2" do
    test "deletes existing task", %{conn: conn} do
      {:ok, created_task} = Tasks.create_task(%{
        "title" => "Task to Delete",
        "priority" => "low",
        "status" => "pending"
      })

      conn = delete(conn, ~p"/api/tasks/#{created_task["id"]}")
      assert response(conn, 204)

      # Verify task is deleted
      assert Tasks.get_task(created_task["id"]) == nil
    end

    test "returns 404 when task not found", %{conn: conn} do
      conn = delete(conn, ~p"/api/tasks/non-existent-id")
      assert %{"error" => "Task not found"} = json_response(conn, 404)
    end

    test "returns empty response on successful deletion", %{conn: conn} do
      {:ok, created_task} = Tasks.create_task(%{
        "title" => "Task to Delete",
        "priority" => "low",
        "status" => "pending"
      })

      conn = delete(conn, ~p"/api/tasks/#{created_task["id"]}")
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

      conn = post(conn, ~p"/api/tasks", task: task_attrs)
      # Should still work even without explicit accept header
      assert %{"task" => _task} = json_response(conn, 201)
    end

    test "handles malformed JSON gracefully", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/tasks", "invalid json")

      assert response(conn, 400)
    end
  end
end