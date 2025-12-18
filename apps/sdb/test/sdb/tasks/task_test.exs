defmodule Sdb.Tasks.TaskTest do
  use ExUnit.Case, async: true

  alias Sdb.Tasks.Task
  import Ecto.Changeset

  # Helper function to extract errors from changeset
  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_atom(key), key) |> to_string()
      end)
    end)
  end

  describe "changeset/2" do
    test "valid changeset with all fields" do
      attrs = %{
        "title" => "Test Task",
        "description" => "Test Description",
        "priority" => "high",
        "status" => "pending",
        "dueDate" => "2024-12-31"
      }

      changeset = Task.changeset(%{}, attrs)

      assert changeset.valid?
      assert get_change(changeset, :title) == "Test Task"
      assert get_change(changeset, :description) == "Test Description"
      assert get_change(changeset, :priority) == "high"
      assert get_change(changeset, :status) == "pending"
      assert get_change(changeset, :dueDate) == "2024-12-31"
      assert get_change(changeset, :id) != nil
      assert get_change(changeset, :createdAt) != nil
      assert get_change(changeset, :updatedAt) != nil
    end

    test "valid changeset with only required fields" do
      attrs = %{
        "title" => "Test Task",
        "priority" => "medium",
        "status" => "in_progress"
      }

      changeset = Task.changeset(%{}, attrs)

      assert changeset.valid?
      assert get_change(changeset, :title) == "Test Task"
      assert get_change(changeset, :priority) == "medium"
      assert get_change(changeset, :status) == "in_progress"
      refute get_change(changeset, :description)
      refute get_change(changeset, :dueDate)
    end

    test "invalid changeset missing required fields" do
      attrs = %{
        "description" => "Test Description"
      }

      changeset = Task.changeset(%{}, attrs)

      refute changeset.valid?
      assert errors_on(changeset)[:title] == ["can't be blank"]
      assert errors_on(changeset)[:priority] == ["can't be blank"]
      assert errors_on(changeset)[:status] == ["can't be blank"]
    end

    test "invalid changeset with wrong priority" do
      attrs = %{
        "title" => "Test Task",
        "priority" => "urgent",
        "status" => "pending"
      }

      changeset = Task.changeset(%{}, attrs)

      refute changeset.valid?
      assert errors_on(changeset)[:priority] == ["is invalid"]
    end

    test "invalid changeset with wrong status" do
      attrs = %{
        "title" => "Test Task",
        "priority" => "high",
        "status" => "done"
      }

      changeset = Task.changeset(%{}, attrs)

      refute changeset.valid?
      assert errors_on(changeset)[:status] == ["is invalid"]
    end

    test "preserves existing id and timestamps" do
      existing_task = %{
        "id" => "existing-uuid",
        "title" => "Updated Task",
        "priority" => "low",
        "status" => "completed",
        "createdAt" => "2024-01-01T00:00:00Z",
        "updatedAt" => "2024-01-01T12:00:00Z"
      }

      attrs = %{
        "title" => "Updated Task",
        "priority" => "low",
        "status" => "completed"
      }

      changeset = Task.changeset(existing_task, attrs)

      assert changeset.valid?
      assert get_change(changeset, :id) == "existing-uuid"
    end
  end

  describe "update_changeset/2" do
    test "valid update changeset" do
      existing_task = %{
        "id" => "existing-uuid",
        "title" => "Original Task",
        "priority" => "low",
        "status" => "pending",
        "createdAt" => "2024-01-01T00:00:00Z",
        "updatedAt" => "2024-01-01T12:00:00Z"
      }

      attrs = %{
        "title" => "Updated Task",
        "priority" => "high",
        "status" => "completed"
      }

      changeset = Task.update_changeset(existing_task, attrs)

      assert changeset.valid?
      assert get_change(changeset, :title) == "Updated Task"
      assert get_change(changeset, :priority) == "high"
      assert get_change(changeset, :status) == "completed"
      refute get_change(changeset, :id)
      refute get_change(changeset, :createdAt)
      assert get_change(changeset, :updatedAt) != nil
    end

    test "update changeset with invalid data" do
      existing_task = %{
        "id" => "existing-uuid",
        "title" => "Original Task",
        "priority" => "low",
        "status" => "pending",
        "createdAt" => "2024-01-01T00:00:00Z",
        "updatedAt" => "2024-01-01T12:00:00Z"
      }

      attrs = %{
        "priority" => "invalid",
        "status" => "invalid"
      }

      changeset = Task.update_changeset(existing_task, attrs)

      refute changeset.valid?
      assert errors_on(changeset)[:priority] == ["is invalid"]
      assert errors_on(changeset)[:status] == ["is invalid"]
    end
  end
end