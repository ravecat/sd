defmodule Sdb.Tasks.Task do
  @moduledoc """
  Task schema and validation using Ecto changesets.
  """

  import Ecto.Changeset

  @fields [:id, :title, :description, :priority, :status, :dueDate, :createdAt, :updatedAt]
  @required [:title, :priority, :status]

  @doc """
  Creates a changeset for a task.
  """
  def changeset(data, attrs) do
    types = %{
      id: :string,
      title: :string,
      description: :string,
      priority: :string,
      status: :string,
      dueDate: :string,
      createdAt: :string,
      updatedAt: :string
    }

    {data, types}
    |> Ecto.Changeset.cast(attrs, @fields)
    |> validate_required(@required)
    |> validate_inclusion(:priority, ["low", "medium", "high"])
    |> validate_inclusion(:status, ["pending", "in_progress", "completed"])
    |> generate_id()
    |> generate_timestamps()
  end

  @doc """
  Creates a changeset for updating an existing task.
  """
  def update_changeset(data, attrs) do
    types = %{
      id: :string,
      title: :string,
      description: :string,
      priority: :string,
      status: :string,
      dueDate: :string,
      createdAt: :string,
      updatedAt: :string
    }

    {data, types}
    |> Ecto.Changeset.cast(attrs, @fields -- [:id, :createdAt])
    |> validate_required(@required)
    |> validate_inclusion(:priority, ["low", "medium", "high"])
    |> validate_inclusion(:status, ["pending", "in_progress", "completed"])
    |> update_timestamp()
  end

  defp generate_id(changeset) do
    # Only generate ID if it doesn't exist in either changeset or original data
    case get_field(changeset, :id) do
      nil ->
        # Check if there's an ID in the original data (check both string and atom keys)
        case Map.get(changeset.data, :id) || Map.get(changeset.data, "id") do
          nil ->
            # No ID exists, generate one
            id = generate_random_string(32)
            put_change(changeset, :id, id)
          existing_id when is_binary(existing_id) ->
            # ID exists in original data, preserve it as a change
            put_change(changeset, :id, existing_id)
        end
      _existing_id ->
        # ID already exists in changeset, don't generate new one
        changeset
    end
  end

  defp generate_random_string(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.encode64()
    |> binary_part(0, length)
    |> String.replace(~r/[^a-zA-Z0-9]/, "")
    |> String.slice(0, length)
  end

  defp generate_timestamps(changeset) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()

    changeset
    |> put_change(:createdAt, now)
    |> put_change(:updatedAt, now)
  end

  defp update_timestamp(changeset) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    put_change(changeset, :updatedAt, now)
  end
end