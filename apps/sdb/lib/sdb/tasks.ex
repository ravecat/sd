defmodule Sdb.Tasks do
  use GenServer
  require Logger

  alias Sdb.Tasks.Task

  @moduledoc """
  GenServer for managing per-user tasks with JSON file persistence.

  Each user gets isolated file storage at {tasks_dir}/{user_id}.json.
  No in-memory caching - reads/writes on each operation.
  """

  # Client API
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc "List all tasks for a user"
  def list_tasks(user_id, server_name \\ __MODULE__) do
    GenServer.call(server_name, {:list_tasks, user_id})
  end

  @doc "Get a task by ID for a user"
  def get_task(user_id, task_id, server_name \\ __MODULE__) do
    GenServer.call(server_name, {:get_task, user_id, task_id})
  end

  @doc "Create a new task for a user"
  def create_task(user_id, attrs, server_name \\ __MODULE__) do
    GenServer.call(server_name, {:create_task, user_id, attrs})
  end

  @doc "Update an existing task for a user"
  def update_task(user_id, task_id, attrs, server_name \\ __MODULE__) do
    GenServer.call(server_name, {:update_task, user_id, task_id, attrs})
  end

  @doc "Delete a task for a user"
  def delete_task(user_id, task_id, server_name \\ __MODULE__) do
    GenServer.call(server_name, {:delete_task, user_id, task_id})
  end

  @doc "Import tasks for a user from a list of task data"
  def import_tasks(user_id, tasks_data, server_name \\ __MODULE__) do
    GenServer.call(server_name, {:import_tasks, user_id, tasks_data})
  end

  @impl true
  def init(opts) do
    # Get base directory from opts (for testing) or application config
    base_dir = Keyword.get(opts, :base_dir) || Application.fetch_env!(:sdb, :tasks_dir)

    # Ensure base directory exists
    File.mkdir_p!(base_dir)

    Logger.info("Tasks GenServer started with base directory: #{base_dir}")

    {:ok, %{base_dir: base_dir}}
  end

  @impl true
  def handle_call({:list_tasks, user_id}, _from, state) do
    tasks = load_user_tasks(state.base_dir, user_id)
    {:reply, tasks, state}
  end

  @impl true
  def handle_call({:get_task, user_id, task_id}, _from, state) do
    tasks = load_user_tasks(state.base_dir, user_id)
    task = Enum.find(tasks, fn t -> t["id"] == task_id end)
    {:reply, task, state}
  end

  @impl true
  def handle_call({:create_task, user_id, attrs}, _from, state) do
    changeset = Task.changeset(%{}, attrs)

    if changeset.valid? do
      new_task = apply_changes(changeset)
      tasks = load_user_tasks(state.base_dir, user_id)
      updated_tasks = [new_task | tasks]

      case write_user_tasks(state.base_dir, user_id, updated_tasks) do
        :ok ->
          Logger.info("Created task #{new_task["id"]} for user #{user_id}")
          {:reply, {:ok, new_task}, state}

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
  def handle_call({:update_task, user_id, task_id, attrs}, _from, state) do
    tasks = load_user_tasks(state.base_dir, user_id)

    case Enum.find_index(tasks, fn t -> t["id"] == task_id end) do
      nil ->
        {:reply, {:error, :not_found}, state}

      index ->
        existing_task = Enum.at(tasks, index)
        existing_task_with_atoms = convert_keys_to_atoms(existing_task)
        changeset = Task.update_changeset(existing_task_with_atoms, attrs)

        if changeset.valid? do
          updated_task = apply_changes(changeset)
          updated_tasks = List.replace_at(tasks, index, updated_task)

          case write_user_tasks(state.base_dir, user_id, updated_tasks) do
            :ok ->
              Logger.info("Updated task #{task_id} for user #{user_id}")
              {:reply, {:ok, updated_task}, state}

            {:error, _reason} ->
              {:reply, {:error, :file_write_failed}, state}
          end
        else
          {:reply, {:error, changeset}, state}
        end
    end
  end

  @impl true
  def handle_call({:delete_task, user_id, task_id}, _from, state) do
    tasks = load_user_tasks(state.base_dir, user_id)

    case Enum.find_index(tasks, fn t -> t["id"] == task_id end) do
      nil ->
        {:reply, {:error, :not_found}, state}

      index ->
        task_to_delete = Enum.at(tasks, index)
        updated_tasks = List.delete_at(tasks, index)

        case write_user_tasks(state.base_dir, user_id, updated_tasks) do
          :ok ->
            Logger.info("Deleted task #{task_id} for user #{user_id}")
            {:reply, {:ok, task_to_delete}, state}

          {:error, reason} ->
            Logger.error("Failed to delete task: #{inspect(reason)}")
            {:reply, {:error, :file_write_failed}, state}
        end
    end
  end

  @impl true
  def handle_call({:import_tasks, user_id, tasks_data}, _from, state) do
    # Validate all tasks first
    results =
      Enum.map(tasks_data, fn task_data ->
        changeset = Task.changeset(%{}, task_data)
        {changeset.valid?, changeset, task_data}
      end)

    # Check if all tasks are valid
    all_valid = Enum.all?(results, fn {valid?, _, _} -> valid? end)

    if all_valid do
      # Load existing tasks
      existing_tasks = load_user_tasks(state.base_dir, user_id)

      # Apply changes to all valid tasks
      new_tasks =
        results
        |> Enum.map(fn {_, changeset, _} -> apply_changes(changeset) end)

      # Merge: replace tasks with same ID, add new ones
      existing_ids = MapSet.new(existing_tasks, fn t -> t["id"] end)
      import_ids = MapSet.new(new_tasks, fn t -> t["id"] end)

      # Keep existing tasks that don't have IDs being imported
      kept_tasks = Enum.reject(existing_tasks, fn t -> MapSet.member?(import_ids, t["id"]) end)

      # Combine kept tasks with imported tasks
      merged_tasks = kept_tasks ++ new_tasks

      case write_user_tasks(state.base_dir, user_id, merged_tasks) do
        :ok ->
          imported_count = length(new_tasks)
          replaced_count = MapSet.size(MapSet.intersection(existing_ids, import_ids))
          added_count = imported_count - replaced_count

          Logger.info(
            "Imported #{imported_count} tasks for user #{user_id} " <>
            "(#{added_count} added, #{replaced_count} replaced)"
          )
          {:reply, {:ok, %{imported: imported_count, added: added_count, replaced: replaced_count}}, state}

        {:error, reason} ->
          Logger.error("Failed to import tasks: #{inspect(reason)}")
          {:reply, {:error, :file_write_failed}, state}
      end
    else
      # Collect errors from invalid changesets
      errors =
        results
        |> Enum.filter(fn {valid?, _, _} -> not valid? end)
        |> Enum.map(fn {_, changeset, _} -> changeset.errors end)

      Logger.warning("Invalid tasks in import: #{inspect(errors)}")
      {:reply, {:error, :invalid_tasks}, state}
    end
  end

  # Private helpers

  defp user_file_path(base_dir, user_id) do
    Path.join(base_dir, "#{user_id}.json")
  end

  defp load_user_tasks(base_dir, user_id) do
    path = user_file_path(base_dir, user_id)

    case File.read(path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, %{"tasks" => tasks}} when is_list(tasks) ->
            tasks

          {:ok, tasks} when is_list(tasks) ->
            # Legacy format support
            tasks

          {:ok, _} ->
            Logger.warning("Invalid JSON format in #{path}")
            []

          {:error, reason} ->
            Logger.error("Failed to decode JSON from #{path}: #{inspect(reason)}")
            []
        end

      {:error, :enoent} ->
        # File doesn't exist yet - return empty list
        []

      {:error, reason} ->
        Logger.error("Failed to read #{path}: #{inspect(reason)}")
        []
    end
  end

  defp write_user_tasks(base_dir, user_id, tasks) do
    path = user_file_path(base_dir, user_id)
    data = %{"tasks" => tasks}

    case File.write(path, Jason.encode!(data, pretty: true)) do
      :ok -> :ok

      {:error, reason} ->
        Logger.error("Failed to write to #{path}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp apply_changes(changeset) do
    result = Ecto.Changeset.apply_changes(changeset)

    result_map =
      case result do
        %_{} = struct -> Map.from_struct(struct)
        map when is_map(map) -> map
        _ -> %{}
      end

    convert_keys_to_strings(result_map)
  end

  defp convert_keys_to_strings(map) when is_map(map) do
    Map.new(map, fn {key, value} ->
      new_key =
        case key do
          atom when is_atom(atom) -> Atom.to_string(atom)
          string when is_binary(string) -> string
          _ -> key
        end

      new_value =
        case value do
          nested_map when is_map(nested_map) -> convert_keys_to_strings(nested_map)
          other -> other
        end

      {new_key, new_value}
    end)
  end

  defp convert_keys_to_atoms(map) when is_map(map) do
    Map.new(map, fn {key, value} ->
      new_key =
        case key do
          atom when is_atom(atom) -> atom
          string when is_binary(string) -> String.to_atom(string)
          _ -> key
        end

      new_value =
        case value do
          nested_map when is_map(nested_map) -> convert_keys_to_atoms(nested_map)
          other -> other
        end

      {new_key, new_value}
    end)
  end
end
