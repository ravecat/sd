import { useState } from 'react'
import type { Task, CreateTaskInput } from '~/shared/task/types'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '~/components/ui/dialog'
import { TaskForm } from './form'
import { Badge } from '~/components/ui/badge'
import { Button } from '~/components/ui/button'
import { Calendar, Edit } from 'lucide-react'

type ModalMode = 'view' | 'edit' | 'create'

interface TaskModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  mode: ModalMode
  task?: Task | null
  onSubmit: (data: CreateTaskInput) => void
  isSubmitting?: boolean
}

const priorityColors = {
  low: 'bg-blue-100 text-blue-800 border-blue-200',
  medium: 'bg-yellow-100 text-yellow-800 border-yellow-200',
  high: 'bg-red-100 text-red-800 border-red-200',
}

const priorityLabels = {
  low: 'Low',
  medium: 'Medium',
  high: 'High',
}

export function TaskModal({
  open,
  onOpenChange,
  mode: initialMode,
  task,
  onSubmit,
  isSubmitting = false,
}: TaskModalProps) {
  const [mode, setMode] = useState<ModalMode>(initialMode)

  const handleClose = () => {
    onOpenChange(false)
    // Reset to initial mode when closing
    setTimeout(() => setMode(initialMode), 200)
  }

  const handleSubmit = (data: CreateTaskInput) => {
    onSubmit(data)
    handleClose()
  }

  const handleEdit = () => {
    setMode('edit')
  }

  const renderContent = () => {
    if (mode === 'view' && task) {
      return (
        <div className="space-y-4">
          <div className="flex items-center gap-2 flex-wrap">
            <Badge variant="outline" className={priorityColors[task.priority]}>
              {priorityLabels[task.priority]}
            </Badge>
            <Badge variant={task.status === 'completed' ? 'default' : 'secondary'}>
              {task.status === 'completed' ? 'Completed' : 'Pending'}
            </Badge>
          </div>

          {task.description && (
            <div>
              <h4 className="text-sm font-semibold mb-2">Description</h4>
              <p className="text-sm text-muted-foreground whitespace-pre-wrap">
                {task.description}
              </p>
            </div>
          )}

          {task.dueDate && (
            <div className="flex items-center gap-2 text-sm">
              <Calendar className="h-4 w-4 text-muted-foreground" />
              <span>
                Due: {new Date(task.dueDate).toLocaleDateString('en-US', {
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric',
                })}
              </span>
            </div>
          )}

          <div className="text-xs text-muted-foreground space-y-1">
            <p>Created: {new Date(task.createdAt).toLocaleString()}</p>
            <p>Updated: {new Date(task.updatedAt).toLocaleString()}</p>
          </div>

          <div className="flex justify-end pt-4">
            <Button onClick={handleEdit}>
              <Edit className="h-4 w-4 mr-2" />
              Edit Task
            </Button>
          </div>
        </div>
      )
    }

    if (mode === 'edit' || mode === 'create') {
      return (
        <TaskForm
          task={mode === 'edit' ? task || undefined : undefined}
          onSubmit={handleSubmit}
          onCancel={handleClose}
          isSubmitting={isSubmitting}
        />
      )
    }

    return null
  }

  const getTitle = () => {
    if (mode === 'view') return task?.title || 'Task Details'
    if (mode === 'edit') return 'Edit Task'
    return 'Create New Task'
  }

  const getDescription = () => {
    if (mode === 'view') return 'View task details'
    if (mode === 'edit') return 'Update task information'
    return 'Fill in the details to create a new task'
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{getTitle()}</DialogTitle>
          <DialogDescription>{getDescription()}</DialogDescription>
        </DialogHeader>
        {renderContent()}
      </DialogContent>
    </Dialog>
  )
}
