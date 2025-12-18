import { useEffect, useState } from 'react'
import type { Task, CreateTaskInput, TaskStatus } from '~/shared/task/types'
import { api } from '~/services/api'
import { TaskList } from '~/features/tasks/list'
import { TaskModal } from '~/features/tasks/modal'
import { TaskFilter } from '~/features/tasks/filter'
import { Button } from '~/components/ui/button'
import { Plus, Loader2 } from 'lucide-react'
import { ThemeProvider } from '~/contexts/theme-context'
import { ThemeToggle } from '~/components/theme-toggle'

export function App() {
  const [tasks, setTasks] = useState<Task[]>([])
  const [filteredTasks, setFilteredTasks] = useState<Task[]>([])
  const [filterStatus, setFilterStatus] = useState<TaskStatus | 'all'>('all')
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [modalMode, setModalMode] = useState<'view' | 'edit' | 'create'>('create')
  const [selectedTask, setSelectedTask] = useState<Task | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)

  useEffect(() => {
    loadTasks()
  }, [])

  useEffect(() => {
    if (filterStatus === 'all') {
      setFilteredTasks(tasks)
    } else {
      setFilteredTasks(tasks.filter((task) => task.status === filterStatus))
    }
  }, [tasks, filterStatus])

  const loadTasks = async () => {
    try {
      setIsLoading(true)
      setError(null)
      const data = await api.getTasks()
      setTasks(data)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load tasks')
    } finally {
      setIsLoading(false)
    }
  }

  const handleCreateTask = async (data: CreateTaskInput) => {
    try {
      setIsSubmitting(true)
      const newTask = await api.createTask(data)
      setTasks((prev) => [...prev, newTask])
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create task')
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleUpdateTask = async (data: CreateTaskInput) => {
    if (!selectedTask) return

    try {
      setIsSubmitting(true)
      const updated = await api.updateTask(selectedTask.id, data)
      if (updated) {
        setTasks((prev) =>
          prev.map((task) => (task.id === selectedTask.id ? updated : task))
        )
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update task')
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleDeleteTask = async (id: string) => {
    if (!confirm('Are you sure you want to delete this task?')) return

    try {
      const success = await api.deleteTask(id)
      if (success) {
        setTasks((prev) => prev.filter((task) => task.id !== id))
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete task')
    }
  }

  const handleToggleStatus = async (id: string) => {
    const task = tasks.find((t) => t.id === id)
    if (!task) return

    const newStatus: TaskStatus = task.status === 'completed' ? 'pending' : 'completed'

    try {
      const updated = await api.updateTask(id, { status: newStatus })
      if (updated) {
        setTasks((prev) => prev.map((t) => (t.id === id ? updated : t)))
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update task status')
    }
  }

  const handleViewTask = (task: Task) => {
    setSelectedTask(task)
    setModalMode('view')
    setIsModalOpen(true)
  }

  const handleEditTask = (task: Task) => {
    setSelectedTask(task)
    setModalMode('edit')
    setIsModalOpen(true)
  }

  const handleNewTask = () => {
    setSelectedTask(null)
    setModalMode('create')
    setIsModalOpen(true)
  }

  const handleModalSubmit = (data: CreateTaskInput) => {
    if (modalMode === 'create') {
      handleCreateTask(data)
    } else if (modalMode === 'edit') {
      handleUpdateTask(data)
    }
  }

  return (
    <ThemeProvider>
      <div className="min-h-screen bg-background">
        <div className="container max-w-7xl mx-auto py-8 px-4">
          <div className="mb-8 flex justify-between items-start">
            <div>
              <h1 className="text-4xl font-bold tracking-tight mb-2">Task Manager</h1>
              <p className="text-muted-foreground">
                Manage your tasks efficiently with our simple task manager
              </p>
            </div>
            <ThemeToggle />
          </div>

        {error && (
          <div className="mb-6 p-4 bg-destructive/10 text-destructive rounded-lg">
            {error}
          </div>
        )}

        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6">
          <TaskFilter value={filterStatus} onChange={setFilterStatus} />
          <Button onClick={handleNewTask}>
            <Plus className="h-4 w-4 mr-2" />
            New Task
          </Button>
        </div>

        {isLoading ? (
          <div className="flex flex-col items-center justify-center py-12">
            <Loader2 className="h-8 w-8 animate-spin text-primary mb-4" />
            <p className="text-muted-foreground">Loading tasks...</p>
          </div>
        ) : (
          <TaskList
            tasks={filteredTasks}
            onEdit={handleEditTask}
            onDelete={handleDeleteTask}
            onToggleStatus={handleToggleStatus}
            onView={handleViewTask}
          />
        )}

        <TaskModal
          open={isModalOpen}
          onOpenChange={setIsModalOpen}
          mode={modalMode}
          task={selectedTask}
          onSubmit={handleModalSubmit}
          isSubmitting={isSubmitting}
        />
      </div>
    </div>
    </ThemeProvider>
  )
}

export default App
