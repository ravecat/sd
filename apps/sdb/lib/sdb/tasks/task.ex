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
    # Check if ID is already in the changeset or the original data
    case get_field(changeset, :id) do
      nil ->
        # Check original data
        case changeset.data do
          %{id: existing_id} when existing_id != nil ->
            changeset  # Keep existing ID
          _ ->
            id = Ecto.UUID.generate()
            put_change(changeset, :id, id)  # Generate new ID
        end
      _ ->
        changeset  # ID already exists in changeset
    end
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