defmodule SdbWeb.TaskJSON do
  @moduledoc """
  JSON views for TaskController.
  """

  def index(%{tasks: tasks}) do
    %{tasks: tasks}
  end

  def show(%{task: task}) do
    %{task: task}
  end

  def error(%{changeset: changeset}) do
    errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_atom(key), key) |> to_string()
      end)
    end)

    %{errors: errors}
  end
end