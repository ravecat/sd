defmodule SdbWeb.TaskController do
  use SdbWeb, :controller

  alias Sdb.Tasks

  action_fallback SdbWeb.FallbackController

  @doc """
  List all tasks
  """
  def index(conn, _params) do
    tasks = Tasks.list_tasks()
    render(conn, :index, tasks: tasks)
  end

  @doc """
  Create a new task
  """
  def create(conn, %{"task" => task_params}) do
    case Tasks.create_task(task_params) do
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
  Show a specific task
  """
  def show(conn, %{"id" => id}) do
    case Tasks.get_task(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Task not found"})

      task ->
        render(conn, :show, task: task)
    end
  end

  @doc """
  Update an existing task
  """
  def update(conn, %{"id" => id, "task" => task_params}) do
    case Tasks.update_task(id, task_params) do
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
  Delete a task
  """
  def delete(conn, %{"id" => id}) do
    case Tasks.delete_task(id) do
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
end