import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { TaskList } from '~/features/tasks/list'
import type { Task } from '~/shared/task/types'

const mockTasks: Task[] = [
  {
    id: '1',
    title: 'Test Task 1',
    description: 'Description for task 1',
    status: 'pending',
    priority: 'high',
    dueDate: '2025-12-25',
    createdAt: '2025-12-18T10:00:00Z',
    updatedAt: '2025-12-18T10:00:00Z',
  },
  {
    id: '2',
    title: 'Test Task 2',
    status: 'completed',
    priority: 'low',
    createdAt: '2025-12-17T10:00:00Z',
    updatedAt: '2025-12-18T11:00:00Z',
  },
]

describe('TaskList', () => {
  it('renders empty state when no tasks', () => {
    const mockHandlers = {
      onEdit: vi.fn(),
      onDelete: vi.fn(),
      onToggleStatus: vi.fn(),
      onView: vi.fn(),
    }

    render(<TaskList tasks={[]} {...mockHandlers} />)

    expect(screen.getByText('No tasks found')).toBeInTheDocument()
    expect(
      screen.getByText('Create your first task to get started')
    ).toBeInTheDocument()
  })

  it('renders list of tasks', () => {
    const mockHandlers = {
      onEdit: vi.fn(),
      onDelete: vi.fn(),
      onToggleStatus: vi.fn(),
      onView: vi.fn(),
    }

    render(<TaskList tasks={mockTasks} {...mockHandlers} />)

    expect(screen.getByText('Test Task 1')).toBeInTheDocument()
    expect(screen.getByText('Test Task 2')).toBeInTheDocument()
    expect(screen.getByText('Description for task 1')).toBeInTheDocument()
  })

  it('displays priority badges correctly', () => {
    const mockHandlers = {
      onEdit: vi.fn(),
      onDelete: vi.fn(),
      onToggleStatus: vi.fn(),
      onView: vi.fn(),
    }

    render(<TaskList tasks={mockTasks} {...mockHandlers} />)

    expect(screen.getByText('High')).toBeInTheDocument()
    expect(screen.getByText('Low')).toBeInTheDocument()
  })

  it('displays status badges correctly', () => {
    const mockHandlers = {
      onEdit: vi.fn(),
      onDelete: vi.fn(),
      onToggleStatus: vi.fn(),
      onView: vi.fn(),
    }

    render(<TaskList tasks={mockTasks} {...mockHandlers} />)

    expect(screen.getAllByText('Pending')).toHaveLength(1)
    expect(screen.getAllByText('Completed')).toHaveLength(1)
  })

  it('calls onEdit when edit button clicked', async () => {
    const user = userEvent.setup()
    const mockHandlers = {
      onEdit: vi.fn(),
      onDelete: vi.fn(),
      onToggleStatus: vi.fn(),
      onView: vi.fn(),
    }

    render(<TaskList tasks={mockTasks} {...mockHandlers} />)

    const editButtons = screen.getAllByRole('button', { name: /edit/i })
    await user.click(editButtons[0])

    expect(mockHandlers.onEdit).toHaveBeenCalledWith(mockTasks[0])
  })

  it('calls onDelete when delete button clicked', async () => {
    const user = userEvent.setup()
    const mockHandlers = {
      onEdit: vi.fn(),
      onDelete: vi.fn(),
      onToggleStatus: vi.fn(),
      onView: vi.fn(),
    }

    render(<TaskList tasks={mockTasks} {...mockHandlers} />)

    const deleteButtons = screen.getAllByRole('button', { name: '' })
    await user.click(deleteButtons[0])

    expect(mockHandlers.onDelete).toHaveBeenCalledWith('1')
  })

  it('calls onToggleStatus when status icon clicked', async () => {
    const user = userEvent.setup()
    const mockHandlers = {
      onEdit: vi.fn(),
      onDelete: vi.fn(),
      onToggleStatus: vi.fn(),
      onView: vi.fn(),
    }

    render(<TaskList tasks={mockTasks} {...mockHandlers} />)

    const statusButton = screen.getByLabelText('Mark as completed')
    await user.click(statusButton)

    expect(mockHandlers.onToggleStatus).toHaveBeenCalledWith('1')
  })

  it('calls onView when card clicked', async () => {
    const user = userEvent.setup()
    const mockHandlers = {
      onEdit: vi.fn(),
      onDelete: vi.fn(),
      onToggleStatus: vi.fn(),
      onView: vi.fn(),
    }

    render(<TaskList tasks={mockTasks} {...mockHandlers} />)

    const card = screen.getByText('Test Task 1').closest('div')?.parentElement
    if (card) {
      await user.click(card)
      expect(mockHandlers.onView).toHaveBeenCalledWith(mockTasks[0])
    }
  })

  it('displays due date when present', () => {
    const mockHandlers = {
      onEdit: vi.fn(),
      onDelete: vi.fn(),
      onToggleStatus: vi.fn(),
      onView: vi.fn(),
    }

    render(<TaskList tasks={mockTasks} {...mockHandlers} />)

    expect(screen.getByText(/Due: 12\/25\/2025/)).toBeInTheDocument()
  })
})
