import type { Task } from '~/shared/task/types'
import {
  Card,
  CardContent,
  CardFooter,
  CardHeader,
  CardTitle,
} from '~/components/ui/card'
import { Badge } from '~/components/ui/badge'
import { Button } from '~/components/ui/button'
import { CheckCircle2, Circle, Edit, Trash2, Calendar } from 'lucide-react'
import { cn } from '~/lib/utils'

interface TaskListProps {
  tasks: Task[]
  onEdit: (task: Task) => void
  onDelete: (id: string) => void
  onToggleStatus: (id: string) => void
  onView: (task: Task) => void
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

export function TaskList({
  tasks,
  onEdit,
  onDelete,
  onToggleStatus,
  onView,
}: TaskListProps) {
  if (tasks.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-12 text-center">
        <Circle className="h-12 w-12 text-muted-foreground mb-4" />
        <h3 className="text-lg font-semibold mb-2">No tasks found</h3>
        <p className="text-sm text-muted-foreground">
          Create your first task to get started
        </p>
      </div>
    )
  }

  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
      {tasks.map((task) => (
        <Card
          key={task.id}
          className={cn(
            'transition-shadow hover:shadow-md cursor-pointer',
            task.status === 'completed' && 'opacity-75'
          )}
          onClick={() => onView(task)}
        >
          <CardHeader className="pb-3">
            <div className="flex items-start justify-between gap-2">
              <CardTitle
                className={cn(
                  'text-base line-clamp-2',
                  task.status === 'completed' && 'line-through text-muted-foreground'
                )}
              >
                {task.title}
              </CardTitle>
              <button
                onClick={(e) => {
                  e.stopPropagation()
                  onToggleStatus(task.id)
                }}
                className="shrink-0 mt-1"
                aria-label={
                  task.status === 'completed'
                    ? 'Mark as pending'
                    : 'Mark as completed'
                }
              >
                {task.status === 'completed' ? (
                  <CheckCircle2 className="h-5 w-5 text-green-600" />
                ) : (
                  <Circle className="h-5 w-5 text-muted-foreground hover:text-primary" />
                )}
              </button>
            </div>
          </CardHeader>

          <CardContent className="pb-3">
            <div className="flex items-center gap-2 flex-wrap">
              <Badge
                variant="outline"
                className={priorityColors[task.priority]}
              >
                {priorityLabels[task.priority]}
              </Badge>
              <Badge variant={task.status === 'completed' ? 'default' : 'secondary'}>
                {task.status === 'completed' ? 'Completed' : 'Pending'}
              </Badge>
            </div>

            {task.description && (
              <p className="text-sm text-muted-foreground mt-3 line-clamp-2">
                {task.description}
              </p>
            )}

            {task.dueDate && (
              <div className="flex items-center gap-1 text-xs text-muted-foreground mt-3">
                <Calendar className="h-3 w-3" />
                <span>Due: {new Date(task.dueDate).toLocaleDateString()}</span>
              </div>
            )}
          </CardContent>

          <CardFooter className="pt-0 gap-2">
            <Button
              size="sm"
              variant="outline"
              onClick={(e) => {
                e.stopPropagation()
                onEdit(task)
              }}
              className="flex-1"
            >
              <Edit className="h-4 w-4 mr-1" />
              Edit
            </Button>
            <Button
              size="sm"
              variant="outline"
              onClick={(e) => {
                e.stopPropagation()
                onDelete(task.id)
              }}
              className="text-destructive hover:bg-destructive hover:text-destructive-foreground"
            >
              <Trash2 className="h-4 w-4" />
            </Button>
          </CardFooter>
        </Card>
      ))}
    </div>
  )
}
