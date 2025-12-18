import { describe, it, expect, vi } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { TaskForm } from '~/features/tasks/form'
import type { Task } from '~/shared/task/types'

describe('TaskForm', () => {
  it('renders all form fields', () => {
    const onSubmit = vi.fn()

    render(<TaskForm onSubmit={onSubmit} />)

    expect(screen.getByLabelText(/title/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/description/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/priority/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/status/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/due date/i)).toBeInTheDocument()
  })

  it('validates required title field', async () => {
    const user = userEvent.setup()
    const onSubmit = vi.fn()

    render(<TaskForm onSubmit={onSubmit} />)

    const submitButton = screen.getByRole('button', { name: /create task/i })
    await user.click(submitButton)

    await waitFor(() => {
      expect(screen.getByText('Title is required')).toBeInTheDocument()
    })
    expect(onSubmit).not.toHaveBeenCalled()
  })

  it('submits form with valid data', async () => {
    const user = userEvent.setup()
    const onSubmit = vi.fn()

    render(<TaskForm onSubmit={onSubmit} />)

    const titleInput = screen.getByLabelText(/title/i)
    await user.type(titleInput, 'New Task')

    const submitButton = screen.getByRole('button', { name: /create task/i })
    await user.click(submitButton)

    await waitFor(() => {
      expect(onSubmit).toHaveBeenCalledWith(
        expect.objectContaining({
          title: 'New Task',
          priority: 'medium',
          status: 'pending',
        })
      )
    })
  })

  it('populates form with task data when editing', () => {
    const task = {
      id: '1',
      title: 'Existing Task',
      description: 'Task description',
      status: 'pending' as const,
      priority: 'high' as const,
      dueDate: '2025-12-25',
      createdAt: '2025-12-18T10:00:00Z',
      updatedAt: '2025-12-18T10:00:00Z',
    }
    const onSubmit = vi.fn()

    render(<TaskForm task={task} onSubmit={onSubmit} />)

    expect(screen.getByDisplayValue('Existing Task')).toBeInTheDocument()
    expect(screen.getByDisplayValue('Task description')).toBeInTheDocument()
    expect(screen.getByDisplayValue('2025-12-25')).toBeInTheDocument()
  })

  it('calls onCancel when cancel button clicked', async () => {
    const user = userEvent.setup()
    const onSubmit = vi.fn()
    const onCancel = vi.fn()

    render(<TaskForm onSubmit={onSubmit} onCancel={onCancel} />)

    const cancelButton = screen.getByRole('button', { name: /cancel/i })
    await user.click(cancelButton)

    expect(onCancel).toHaveBeenCalled()
    expect(onSubmit).not.toHaveBeenCalled()
  })

  it('disables submit button when submitting', () => {
    const onSubmit = vi.fn()

    render(<TaskForm onSubmit={onSubmit} isSubmitting={true} />)

    const submitButton = screen.getByRole('button', { name: /saving/i })
    expect(submitButton).toBeDisabled()
  })

  it('validates title max length', async () => {
    const user = userEvent.setup()
    const onSubmit = vi.fn()

    render(<TaskForm onSubmit={onSubmit} />)

    const titleInput = screen.getByLabelText(/title/i)
    await user.type(titleInput, 'a'.repeat(201))

    const submitButton = screen.getByRole('button', { name: /create task/i })
    await user.click(submitButton)

    await waitFor(() => {
      expect(screen.getByText('Title is too long')).toBeInTheDocument()
    })
  })
})
