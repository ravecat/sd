defmodule Sdb.Tasks do
  use GenServer
  require Logger

  alias Sdb.Tasks.Task

  @moduledoc """
  GenServer for managing tasks with JSON file persistence.

  This module provides a GenServer interface for CRUD operations on tasks
  stored in a JSON file. Each operation reads the file, mutates the data,
  and writes it back to ensure consistency without in-memory caching.
  """

  # Client API
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc "List all tasks"
  def list_tasks(server_name \\ __MODULE__) do
    GenServer.call(server_name, :list_tasks)
  end

  @doc "Get a task by ID"
  def get_task(id, server_name \\ __MODULE__) do
    GenServer.call(server_name, {:get_task, id})
  end

  @doc "Create a new task"
  def create_task(attrs, server_name \\ __MODULE__) do
    GenServer.call(server_name, {:create_task, attrs})
  end

  @doc "Update an existing task"
  def update_task(id, attrs, server_name \\ __MODULE__) do
    GenServer.call(server_name, {:update_task, id, attrs})
  end

  @doc "Delete a task"
  def delete_task(id, server_name \\ __MODULE__) do
    GenServer.call(server_name, {:delete_task, id})
  end

  @impl true
  def init(opts) do
    # Allow path to be passed in opts for testing, otherwise use application config
    path = Keyword.get(opts, :path) || Application.fetch_env!(:sdb, :tasks_json_path)

    # Ensure directory exists
    File.mkdir_p!(Path.dirname(path))

    # Load initial data or create empty file
    tasks = load_or_create_file(path)

    Logger.info("Tasks GenServer started with path: #{path}, loaded #{length(tasks)} tasks")

    {:ok, %{path: path, tasks: tasks}}
  end

  @impl true
  def handle_call(:list_tasks, _from, state) do
    {:reply, state.tasks, state}
  end

  @impl true
  def handle_call({:get_task, id}, _from, state) do
    task = Enum.find(state.tasks, fn task -> task["id"] == id end)
    {:reply, task, state}
  end

  @impl true
  def handle_call({:create_task, attrs}, _from, state) do
    changeset = Task.changeset(%{}, attrs)

    if changeset.valid? do
      new_task = apply_changes(changeset)
      updated_tasks = [new_task | state.tasks]

      case write_tasks_to_file(state.path, updated_tasks) do
        :ok ->
          Logger.info("Created task: #{new_task["id"]}")
          {:reply, {:ok, new_task}, %{state | tasks: updated_tasks}}

        {:error, reason} ->
          Logger.error("Failed to create task: #{inspect(reason)}")
          {:reply, {:error, :file_write_failed}, state}
      end
    else
      Logger.warning("Invalid task data: #{inspect(changeset.errors)}")
      {:reply, {:error, changeset}, state}
    end
  end

  @impl true
  def handle_call({:update_task, id, attrs}, _from, state) do
    case Enum.find_index(state.tasks, fn task -> task["id"] == id end) do
      nil ->
        {:reply, {:error, :not_found}, state}

      index ->
        existing_task = Enum.at(state.tasks, index)

        # Convert string keys to atom keys for Ecto changeset compatibility
        existing_task_with_atoms = convert_keys_to_atoms(existing_task)
        changeset = Task.update_changeset(existing_task_with_atoms, attrs)

        if changeset.valid? do
          updated_task = apply_changes(changeset)
          updated_tasks = List.replace_at(state.tasks, index, updated_task)

          case write_tasks_to_file(state.path, updated_tasks) do
            :ok ->
              {:reply, {:ok, updated_task}, %{state | tasks: updated_tasks}}

            {:error, _reason} ->
              {:reply, {:error, :file_write_failed}, state}
          end
        else
          {:reply, {:error, changeset}, state}
        end
    end
  end

  @impl true
  def handle_call({:delete_task, id}, _from, state) do
    case Enum.find_index(state.tasks, fn task -> task["id"] == id end) do
      nil ->
        {:reply, {:error, :not_found}, state}

      index ->
        task_to_delete = Enum.at(state.tasks, index)
        updated_tasks = List.delete_at(state.tasks, index)

        case write_tasks_to_file(state.path, updated_tasks) do
          :ok ->
            Logger.info("Deleted task: #{id}")
            {:reply, {:ok, task_to_delete}, %{state | tasks: updated_tasks}}

          {:error, reason} ->
            Logger.error("Failed to delete task: #{inspect(reason)}")
            {:reply, {:error, :file_write_failed}, state}
        end
    end
  end

  defp load_or_create_file(path) do
    case File.read(path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, %{"tasks" => tasks}} when is_list(tasks) ->
            Logger.info("Loaded #{length(tasks)} tasks from #{path}")
            tasks

          {:ok, data} ->
            Logger.warning("Invalid JSON format in #{path}, expected {\"tasks\": []}")
            # Try to handle cases where file contains just an array
            case data do
              tasks when is_list(tasks) ->
                Logger.info("Converted array format to tasks format")
                write_tasks_to_file(path, tasks)
                tasks
              _ ->
                Logger.info("Creating new tasks file")
                File.write!(path, Jason.encode!(%{"tasks" => []}))
                []
            end

          {:error, reason} ->
            Logger.error("Failed to decode JSON from #{path}: #{inspect(reason)}")
            File.write!(path, Jason.encode!(%{"tasks" => []}))
            []
        end

      {:error, :enoent} ->
        Logger.info("Tasks file doesn't exist, creating new one at #{path}")
        File.write!(path, Jason.encode!(%{"tasks" => []}))
        []

      {:error, reason} ->
        Logger.error("Failed to read tasks file #{path}: #{inspect(reason)}")
        []
    end
  end

  defp write_tasks_to_file(path, tasks) do
    data = %{"tasks" => tasks}

    case File.write(path, Jason.encode!(data, pretty: true)) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to write tasks to file #{path}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp apply_changes(changeset) do
    # Apply changes
    result = Ecto.Changeset.apply_changes(changeset)

    # Convert struct to map and ensure string keys
    result_map = case result do
      %_{} = struct -> Map.from_struct(struct)
      map when is_map(map) -> map
      _ -> %{}
    end

    # Convert atom keys to string keys recursively
    convert_keys_to_strings(result_map)
  end

  defp convert_keys_to_strings(map) when is_map(map) do
    Map.new(map, fn {key, value} ->
      new_key = case key do
        atom when is_atom(atom) -> Atom.to_string(atom)
        string when is_binary(string) -> string
        _ -> key
      end

      new_value = case value do
        nested_map when is_map(nested_map) -> convert_keys_to_strings(nested_map)
        other -> other
      end

      {new_key, new_value}
    end)
  end

  defp convert_keys_to_atoms(map) when is_map(map) do
    Map.new(map, fn {key, value} ->
      new_key = case key do
        atom when is_atom(atom) -> atom
        string when is_binary(string) -> String.to_atom(string)
        _ -> key
      end

      new_value = case value do
        nested_map when is_map(nested_map) -> convert_keys_to_atoms(nested_map)
        other -> other
      end

      {new_key, new_value}
    end)
  end
end
