import type { Task, CreateTaskInput, UpdateTaskInput } from '~/shared/task/types'

// Mock data for development
const mockTasks: Task[] = [
  {
    id: '1',
    title: 'Setup project structure',
    description: 'Initialize the project with necessary dependencies',
    status: 'completed',
    priority: 'high',
    dueDate: '2025-12-20',
    createdAt: '2025-12-15T10:00:00Z',
    updatedAt: '2025-12-16T14:30:00Z',
  },
  {
    id: '2',
    title: 'Implement authentication',
    description: 'Add user login and registration',
    status: 'pending',
    priority: 'high',
    dueDate: '2025-12-22',
    createdAt: '2025-12-16T09:00:00Z',
    updatedAt: '2025-12-16T09:00:00Z',
  },
  {
    id: '3',
    title: 'Write documentation',
    status: 'pending',
    priority: 'low',
    createdAt: '2025-12-17T11:00:00Z',
    updatedAt: '2025-12-17T11:00:00Z',
  },
]

let tasks = [...mockTasks]

// Simulate API delay
const delay = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms))

export const api = {
  async getTasks(): Promise<Task[]> {
    await delay(300)
    return [...tasks]
  },

  async getTask(id: string): Promise<Task | null> {
    await delay(200)
    return tasks.find((task) => task.id === id) || null
  },

  async createTask(input: CreateTaskInput): Promise<Task> {
    await delay(400)
    const newTask: Task = {
      ...input,
      id: Math.random().toString(36).substring(2, 9),
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    }
    tasks.push(newTask)
    return newTask
  },

  async updateTask(id: string, input: UpdateTaskInput): Promise<Task | null> {
    await delay(400)
    const index = tasks.findIndex((task) => task.id === id)
    if (index === -1) return null

    tasks[index] = {
      ...tasks[index],
      ...input,
      updatedAt: new Date().toISOString(),
    }
    return tasks[index]
  },

  async deleteTask(id: string): Promise<boolean> {
    await delay(300)
    const index = tasks.findIndex((task) => task.id === id)
    if (index === -1) return false

    tasks.splice(index, 1)
    return true
  },
}

// Real API calls (commented out for now)
/*
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:4000/api'

export const api = {
  async getTasks(): Promise<Task[]> {
    const response = await fetch(`${API_BASE_URL}/tasks`)
    if (!response.ok) throw new Error('Failed to fetch tasks')
    return response.json()
  },

  async getTask(id: string): Promise<Task | null> {
    const response = await fetch(`${API_BASE_URL}/tasks/${id}`)
    if (response.status === 404) return null
    if (!response.ok) throw new Error('Failed to fetch task')
    return response.json()
  },

  async createTask(input: CreateTaskInput): Promise<Task> {
    const response = await fetch(`${API_BASE_URL}/tasks`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(input),
    })
    if (!response.ok) throw new Error('Failed to create task')
    return response.json()
  },

  async updateTask(id: string, input: UpdateTaskInput): Promise<Task | null> {
    const response = await fetch(`${API_BASE_URL}/tasks/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(input),
    })
    if (response.status === 404) return null
    if (!response.ok) throw new Error('Failed to update task')
    return response.json()
  },

  async deleteTask(id: string): Promise<boolean> {
    const response = await fetch(`${API_BASE_URL}/tasks/${id}`, {
      method: 'DELETE',
    })
    if (response.status === 404) return false
    if (!response.ok) throw new Error('Failed to delete task')
    return true
  },
}
*/
