defmodule SdbWeb.TaskController do
  use SdbWeb, :controller

  alias Sdb.Tasks

  action_fallback SdbWeb.FallbackController

  @doc """
  List all tasks for current user
  """
  def index(conn, _params) do
    user_id = conn.assigns.user_id
    tasks = Tasks.list_tasks(user_id)
    render(conn, :index, tasks: tasks)
  end

  @doc """
  Create a new task for current user
  """
  def create(conn, %{"task" => task_params}) do
    user_id = conn.assigns.user_id

    case Tasks.create_task(user_id, task_params) do
      {:ok, task} ->
        conn
        |> put_status(:created)
        |> render(:show, task: task)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, changeset: changeset)

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: to_string(reason)})
    end
  end

  @doc """
  Show a specific task for current user
  """
  def show(conn, %{"id" => id}) do
    user_id = conn.assigns.user_id

    case Tasks.get_task(user_id, id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Task not found"})

      task ->
        render(conn, :show, task: task)
    end
  end

  @doc """
  Update an existing task for current user
  """
  def update(conn, %{"id" => id, "task" => task_params}) do
    user_id = conn.assigns.user_id

    case Tasks.update_task(user_id, id, task_params) do
      {:ok, task} ->
        render(conn, :show, task: task)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Task not found"})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, changeset: changeset)

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: to_string(reason)})
    end
  end

  @doc """
  Delete a task for current user
  """
  def delete(conn, %{"id" => id}) do
    user_id = conn.assigns.user_id

    case Tasks.delete_task(user_id, id) do
      {:ok, _task} ->
        conn
        |> put_status(:no_content)
        |> send_resp(:no_content, "")

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Task not found"})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: to_string(reason)})
    end
  end

  @doc """
  Export all tasks for current user as JSON file
  """
  def export(conn, _params) do
    user_id = conn.assigns.user_id
    tasks = Tasks.list_tasks(user_id)

    conn
    |> put_resp_content_type("application/json")
    |> put_resp_header("content-disposition", ~s(attachment; filename="tasks.json"))
    |> send_resp(200, Jason.encode!(%{tasks: tasks}))
  end
end
