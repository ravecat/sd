import * as z from 'zod'

export const taskStatusSchema = z.enum(['pending', 'completed'])
export const taskPrioritySchema = z.enum(['low', 'medium', 'high'])

export const taskSchema = z.object({
  id: z.string(),
  title: z.string().min(1, 'Title is required').max(200, 'Title is too long'),
  description: z.string().max(1000, 'Description is too long').optional(),
  status: taskStatusSchema,
  priority: taskPrioritySchema,
  dueDate: z.string().optional(),
  createdAt: z.string(),
  updatedAt: z.string(),
})

export const createTaskInputSchema = taskSchema.omit({
  id: true,
  createdAt: true,
  updatedAt: true,
})

export const updateTaskInputSchema = createTaskInputSchema.partial()
