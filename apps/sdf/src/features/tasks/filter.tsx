import type { TaskStatus } from '~/shared/task/types'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '~/components/ui/select'
import { Label } from '~/components/ui/label'

type FilterValue = TaskStatus | 'all'

interface TaskFilterProps {
  value: FilterValue
  onChange: (value: FilterValue) => void
}

export function TaskFilter({ value, onChange }: TaskFilterProps) {
  return (
    <div className="flex items-center gap-2">
      <Label htmlFor="status-filter" className="text-sm font-medium">
        Filter by status:
      </Label>
      <Select value={value} onValueChange={onChange}>
        <SelectTrigger id="status-filter" className="w-[180px]">
          <SelectValue placeholder="All tasks" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="all">All tasks</SelectItem>
          <SelectItem value="pending">Pending</SelectItem>
          <SelectItem value="completed">Completed</SelectItem>
        </SelectContent>
      </Select>
    </div>
  )
}
