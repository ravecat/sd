export type TaskStatus = 'pending' | 'completed'
export type TaskPriority = 'low' | 'medium' | 'high'

export interface Task {
  id: string
  title: string
  description?: string
  status: TaskStatus
  priority: TaskPriority
  dueDate?: string
  createdAt: string
  updatedAt: string
}

export type CreateTaskInput = Omit<Task, 'id' | 'createdAt' | 'updatedAt'>
export type UpdateTaskInput = Partial<CreateTaskInput>
