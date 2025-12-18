import type { Task, CreateTaskInput, UpdateTaskInput } from '~/shared/task/types'
import config from '~/lib/env'

const API_BASE_URL = config.API_BASE_URL

export const api = {
  async getTasks(): Promise<Task[]> {
    const response = await fetch(`${API_BASE_URL}/tasks`, {
      credentials: 'include',
    })
    if (!response.ok) throw new Error('Failed to fetch tasks')

    const data = await response.json()

    // Handle response format: { "tasks": [...] }
    if (data && data.tasks) {
      return data.tasks
    }

    // Handle direct array response
    if (Array.isArray(data)) {
      return data
    }

    return []
  },

  async getTask(id: string): Promise<Task | null> {
    const response = await fetch(`${API_BASE_URL}/tasks/${id}`, {
      credentials: 'include',
    })

    if (response.status === 404) return null
    if (!response.ok) throw new Error('Failed to fetch task')

    const data = await response.json()

    // Handle response format: { "task": {...} }
    if (data && data.task) {
      return data.task
    }

    // Handle direct task response
    if (data) {
      return data
    }

    return null
  },

  async createTask(input: CreateTaskInput): Promise<Task> {
    const response = await fetch(`${API_BASE_URL}/tasks`, {
      method: 'POST',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ task: input }),
    })

    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.errors?.join(', ') || 'Failed to create task')
    }

    const data = await response.json()

    // Handle response format: { "task": {...} }
    if (data && data.task) {
      return data.task
    }

    // Handle direct task response
    if (data) {
      return data
    }

    throw new Error('Invalid response format')
  },

  async updateTask(id: string, input: UpdateTaskInput): Promise<Task | null> {
    const response = await fetch(`${API_BASE_URL}/tasks/${id}`, {
      method: 'PUT',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ task: input }),
    })

    if (response.status === 404) return null
    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.errors?.join(', ') || 'Failed to update task')
    }

    const data = await response.json()

    // Handle response format: { "task": {...} }
    if (data && data.task) {
      return data.task
    }

    // Handle direct task response
    if (data) {
      return data
    }

    throw new Error('Invalid response format')
  },

  async deleteTask(id: string): Promise<boolean> {
    const response = await fetch(`${API_BASE_URL}/tasks/${id}`, {
      method: 'DELETE',
      credentials: 'include',
    })

    if (response.status === 404) {
      const error = await response.json()
      if (error.error === "Task not found") return false
    }

    if (!response.ok && response.status !== 204) {
      const error = await response.json()
      throw new Error(error.errors?.join(', ') || 'Failed to delete task')
    }

    // DELETE returns 204 with empty body on success
    return response.status === 204
  },

  async exportTasks(): Promise<void> {
    const response = await fetch(`${API_BASE_URL}/tasks/export`, {
      credentials: 'include',
    })

    if (!response.ok) throw new Error('Failed to export tasks')

    const blob = await response.blob()
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = 'tasks.json'
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)
  },

  async importTasks(file: File): Promise<{ imported: number; added: number; replaced: number }> {
    const formData = new FormData()
    formData.append('file', file)

    const response = await fetch(`${API_BASE_URL}/tasks/import`, {
      method: 'POST',
      credentials: 'include',
      body: formData,
    })

    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.error || 'Failed to import tasks')
    }

    const data = await response.json()
    return {
      imported: data.imported,
      added: data.added,
      replaced: data.replaced,
    }
  },
}
