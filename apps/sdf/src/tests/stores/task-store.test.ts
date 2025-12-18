import { describe, it, expect, vi, beforeEach } from 'vitest'
import { renderHook, act, waitFor } from '@testing-library/react'
import { useTaskStore, useFilteredTasks } from '~/stores/task-store'
import * as apiModule from '~/services/api'

// Mock the API module
vi.mock('~/services/api', () => ({
  api: {
    getTasks: vi.fn(),
    createTask: vi.fn(),
    updateTask: vi.fn(),
    deleteTask: vi.fn(),
  },
}))

const mockApi = apiModule.api as any

describe('useTaskStore', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    // Reset store to initial state
    useTaskStore.setState({
      tasks: [],
      isLoading: false,
      error: null,
      filterStatus: 'all',
    })
  })

  describe('fetchTasks', () => {
    it('loads tasks successfully', async () => {
      const mockTasks = [
        {
          id: '1',
          title: 'Test Task',
          status: 'pending' as const,
          priority: 'high' as const,
          createdAt: '2025-12-18T10:00:00Z',
          updatedAt: '2025-12-18T10:00:00Z',
        },
      ]

      mockApi.getTasks.mockResolvedValueOnce(mockTasks)

      const { result } = renderHook(() => useTaskStore())

      await act(async () => {
        await result.current.fetchTasks()
      })

      await waitFor(() => {
        expect(result.current.tasks).toEqual(mockTasks)
        expect(result.current.isLoading).toBe(false)
        expect(result.current.error).toBeNull()
      })
    })

    it('handles fetch error', async () => {
      mockApi.getTasks.mockRejectedValueOnce(new Error('Network error'))

      const { result } = renderHook(() => useTaskStore())

      await act(async () => {
        await result.current.fetchTasks()
      })

      await waitFor(() => {
        expect(result.current.error).toBe('Network error')
        expect(result.current.isLoading).toBe(false)
        expect(result.current.tasks).toEqual([])
      })
    })

    it('sets loading state during fetch', async () => {
      mockApi.getTasks.mockImplementation(
        () => new Promise((resolve) => setTimeout(() => resolve([]), 100))
      )

      const { result } = renderHook(() => useTaskStore())

      act(() => {
        result.current.fetchTasks()
      })

      expect(result.current.isLoading).toBe(true)

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false)
      })
    })
  })

  describe('createTask', () => {
    it('creates a new task', async () => {
      const newTask = {
        id: '2',
        title: 'New Task',
        description: 'Description',
        status: 'pending' as const,
        priority: 'medium' as const,
        createdAt: '2025-12-18T12:00:00Z',
        updatedAt: '2025-12-18T12:00:00Z',
      }

      mockApi.createTask.mockResolvedValueOnce(newTask)

      const { result } = renderHook(() => useTaskStore())

      await act(async () => {
        await result.current.createTask({
          title: 'New Task',
          description: 'Description',
          status: 'pending',
          priority: 'medium',
        })
      })

      await waitFor(() => {
        expect(result.current.tasks).toContainEqual(newTask)
      })
    })

    it('handles create error', async () => {
      mockApi.createTask.mockRejectedValueOnce(new Error('Create failed'))

      const { result } = renderHook(() => useTaskStore())

      await expect(
        act(async () => {
          await result.current.createTask({
            title: 'New Task',
            status: 'pending',
            priority: 'medium',
          })
        })
      ).rejects.toThrow('Create failed')

      await waitFor(() => {
        expect(result.current.error).toBe('Create failed')
      })
    })
  })

  describe('updateTask', () => {
    it('updates an existing task', async () => {
      const initialTask = {
        id: '1',
        title: 'Original',
        status: 'pending' as const,
        priority: 'high' as const,
        createdAt: '2025-12-18T10:00:00Z',
        updatedAt: '2025-12-18T10:00:00Z',
      }

      const updatedTask = {
        ...initialTask,
        title: 'Updated',
        updatedAt: '2025-12-18T12:00:00Z',
      }

      // Set initial state
      useTaskStore.setState({ tasks: [initialTask] })

      mockApi.updateTask.mockResolvedValueOnce(updatedTask)

      const { result } = renderHook(() => useTaskStore())

      await act(async () => {
        await result.current.updateTask('1', { title: 'Updated' })
      })

      await waitFor(() => {
        expect(result.current.tasks[0].title).toBe('Updated')
      })
    })

    it('handles update error', async () => {
      mockApi.updateTask.mockRejectedValueOnce(new Error('Update failed'))

      const { result } = renderHook(() => useTaskStore())

      await expect(
        act(async () => {
          await result.current.updateTask('1', { title: 'Updated' })
        })
      ).rejects.toThrow('Update failed')

      await waitFor(() => {
        expect(result.current.error).toBe('Update failed')
      })
    })
  })

  describe('deleteTask', () => {
    it('deletes a task', async () => {
      const task = {
        id: '1',
        title: 'To Delete',
        status: 'pending' as const,
        priority: 'high' as const,
        createdAt: '2025-12-18T10:00:00Z',
        updatedAt: '2025-12-18T10:00:00Z',
      }

      // Set initial state
      useTaskStore.setState({ tasks: [task] })

      mockApi.deleteTask.mockResolvedValueOnce(true)

      const { result } = renderHook(() => useTaskStore())

      await act(async () => {
        await result.current.deleteTask('1')
      })

      await waitFor(() => {
        expect(result.current.tasks).toHaveLength(0)
      })
    })

    it('handles delete error', async () => {
      mockApi.deleteTask.mockRejectedValueOnce(new Error('Delete failed'))

      const { result } = renderHook(() => useTaskStore())

      await expect(
        act(async () => {
          await result.current.deleteTask('1')
        })
      ).rejects.toThrow('Delete failed')

      await waitFor(() => {
        expect(result.current.error).toBe('Delete failed')
      })
    })
  })

  describe('toggleStatus', () => {
    it('toggles task from pending to completed', async () => {
      const task = {
        id: '1',
        title: 'Test Task',
        status: 'pending' as const,
        priority: 'high' as const,
        createdAt: '2025-12-18T10:00:00Z',
        updatedAt: '2025-12-18T10:00:00Z',
      }

      const toggledTask = { ...task, status: 'completed' as const }

      // Set initial state
      useTaskStore.setState({ tasks: [task] })

      mockApi.updateTask.mockResolvedValueOnce(toggledTask)

      const { result } = renderHook(() => useTaskStore())

      await act(async () => {
        await result.current.toggleStatus('1')
      })

      await waitFor(() => {
        expect(result.current.tasks[0].status).toBe('completed')
      })

      expect(mockApi.updateTask).toHaveBeenCalledWith('1', {
        status: 'completed',
      })
    })

    it('toggles task from completed to pending', async () => {
      const task = {
        id: '1',
        title: 'Test Task',
        status: 'completed' as const,
        priority: 'high' as const,
        createdAt: '2025-12-18T10:00:00Z',
        updatedAt: '2025-12-18T10:00:00Z',
      }

      const toggledTask = { ...task, status: 'pending' as const }

      // Set initial state
      useTaskStore.setState({ tasks: [task] })

      mockApi.updateTask.mockResolvedValueOnce(toggledTask)

      const { result } = renderHook(() => useTaskStore())

      await act(async () => {
        await result.current.toggleStatus('1')
      })

      await waitFor(() => {
        expect(result.current.tasks[0].status).toBe('pending')
      })

      expect(mockApi.updateTask).toHaveBeenCalledWith('1', {
        status: 'pending',
      })
    })
  })

  describe('setFilterStatus', () => {
    it('changes filter status', () => {
      const { result } = renderHook(() => useTaskStore())

      act(() => {
        result.current.setFilterStatus('completed')
      })

      expect(result.current.filterStatus).toBe('completed')

      act(() => {
        result.current.setFilterStatus('pending')
      })

      expect(result.current.filterStatus).toBe('pending')

      act(() => {
        result.current.setFilterStatus('all')
      })

      expect(result.current.filterStatus).toBe('all')
    })
  })
})

describe('useFilteredTasks', () => {
  beforeEach(() => {
    useTaskStore.setState({
      tasks: [],
      isLoading: false,
      error: null,
      filterStatus: 'all',
    })
  })

  it('returns all tasks when filter is "all"', () => {
    const tasks = [
      {
        id: '1',
        title: 'Pending Task',
        status: 'pending' as const,
        priority: 'high' as const,
        createdAt: '2025-12-18T10:00:00Z',
        updatedAt: '2025-12-18T10:00:00Z',
      },
      {
        id: '2',
        title: 'Completed Task',
        status: 'completed' as const,
        priority: 'low' as const,
        createdAt: '2025-12-18T10:00:00Z',
        updatedAt: '2025-12-18T10:00:00Z',
      },
    ]

    useTaskStore.setState({ tasks, filterStatus: 'all' })

    const { result } = renderHook(() => useFilteredTasks())

    expect(result.current).toHaveLength(2)
    expect(result.current).toEqual(tasks)
  })

  it('returns only pending tasks when filter is "pending"', () => {
    const tasks = [
      {
        id: '1',
        title: 'Pending Task',
        status: 'pending' as const,
        priority: 'high' as const,
        createdAt: '2025-12-18T10:00:00Z',
        updatedAt: '2025-12-18T10:00:00Z',
      },
      {
        id: '2',
        title: 'Completed Task',
        status: 'completed' as const,
        priority: 'low' as const,
        createdAt: '2025-12-18T10:00:00Z',
        updatedAt: '2025-12-18T10:00:00Z',
      },
    ]

    useTaskStore.setState({ tasks, filterStatus: 'pending' })

    const { result } = renderHook(() => useFilteredTasks())

    expect(result.current).toHaveLength(1)
    expect(result.current[0].status).toBe('pending')
  })

  it('returns only completed tasks when filter is "completed"', () => {
    const tasks = [
      {
        id: '1',
        title: 'Pending Task',
        status: 'pending' as const,
        priority: 'high' as const,
        createdAt: '2025-12-18T10:00:00Z',
        updatedAt: '2025-12-18T10:00:00Z',
      },
      {
        id: '2',
        title: 'Completed Task',
        status: 'completed' as const,
        priority: 'low' as const,
        createdAt: '2025-12-18T10:00:00Z',
        updatedAt: '2025-12-18T10:00:00Z',
      },
    ]

    useTaskStore.setState({ tasks, filterStatus: 'completed' })

    const { result } = renderHook(() => useFilteredTasks())

    expect(result.current).toHaveLength(1)
    expect(result.current[0].status).toBe('completed')
  })

  it('returns empty array when no tasks match filter', () => {
    const tasks = [
      {
        id: '1',
        title: 'Pending Task',
        status: 'pending' as const,
        priority: 'high' as const,
        createdAt: '2025-12-18T10:00:00Z',
        updatedAt: '2025-12-18T10:00:00Z',
      },
    ]

    useTaskStore.setState({ tasks, filterStatus: 'completed' })

    const { result } = renderHook(() => useFilteredTasks())

    expect(result.current).toHaveLength(0)
  })
})
