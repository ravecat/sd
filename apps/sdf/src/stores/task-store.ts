import { create } from 'zustand'
import { devtools } from 'zustand/middleware'
import type { Task, CreateTaskInput, UpdateTaskInput, TaskStatus } from '~/shared/task/types'
import { api } from '~/services/api'

interface TaskState {
  tasks: Task[]
  isLoading: boolean
  error: string | null
  filterStatus: TaskStatus | 'all'
}

interface TaskActions {
  fetchTasks: () => Promise<void>
  createTask: (input: CreateTaskInput) => Promise<void>
  updateTask: (id: string, input: UpdateTaskInput) => Promise<void>
  deleteTask: (id: string) => Promise<void>
  toggleStatus: (id: string) => Promise<void>
  setFilterStatus: (status: TaskStatus | 'all') => void
}

type TaskStore = TaskState & TaskActions

export const useTaskStore = create<TaskStore>()(
  devtools(
    (set, get) => ({
      // State
      tasks: [],
      isLoading: false,
      error: null,
      filterStatus: 'all',

      // Actions
      fetchTasks: async () => {
        set({ isLoading: true, error: null })
        try {
          const tasks = await api.getTasks()
          set({ tasks, isLoading: false })
        } catch (err) {
          set({
            error: err instanceof Error ? err.message : 'Failed to load tasks',
            isLoading: false,
          })
        }
      },

      createTask: async (input: CreateTaskInput) => {
        try {
          const newTask = await api.createTask(input)
          set((state) => ({ tasks: [...state.tasks, newTask] }))
        } catch (err) {
          set({
            error: err instanceof Error ? err.message : 'Failed to create task',
          })
          throw err
        }
      },

      updateTask: async (id: string, input: UpdateTaskInput) => {
        try {
          const updated = await api.updateTask(id, input)

          if (updated) {
            set((state) => ({
              tasks: state.tasks.map((task) =>
                task.id === id ? updated : task
              ),
            }))
          }
        } catch (err) {
          set({
            error: err instanceof Error ? err.message : 'Failed to update task',
          })
          throw err
        }
      },

      deleteTask: async (id: string) => {
        try {
          const success = await api.deleteTask(id)
          if (success) {
            set((state) => ({
              tasks: state.tasks.filter((task) => task.id !== id),
            }))
          }
        } catch (err) {
          set({
            error: err instanceof Error ? err.message : 'Failed to delete task',
          })
          throw err
        }
      },

      toggleStatus: async (id: string) => {
        const task = get().tasks.find((t) => t.id === id)
        if (!task) return

        const newStatus: TaskStatus =
          task.status === 'completed' ? 'pending' : 'completed'

        try {
          const updated = await api.updateTask(id, { status: newStatus })
          if (updated) {
            set((state) => ({
              tasks: state.tasks.map((t) => (t.id === id ? updated : t)),
            }))
          }
        } catch (err) {
          set({
            error:
              err instanceof Error ? err.message : 'Failed to update task status',
          })
          throw err
        }
      },

      setFilterStatus: (status: TaskStatus | 'all') => {
        set({ filterStatus: status })
      },
    }),
    { name: 'task-store' }
  )
)

export const useFilteredTasks = () => {
  const tasks = useTaskStore((state) => state.tasks)
  const filterStatus = useTaskStore((state) => state.filterStatus)

  if (filterStatus === 'all') {
    return tasks
  }

  return tasks.filter((task) => task.status === filterStatus)
}
