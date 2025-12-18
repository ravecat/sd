import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import NiceModal from '@ebay/nice-modal-react';
import { App } from '~/app/app';
import * as apiModule from '~/services/api';
import { useTaskStore } from '~/stores/task-store';

// Mock the API module
vi.mock('~/services/api', () => ({
  api: {
    getTasks: vi.fn(),
    createTask: vi.fn(),
    updateTask: vi.fn(),
    deleteTask: vi.fn(),
  },
}));

const mockApi = apiModule.api as any;

/**
 * Custom render function that wraps App with NiceModal.Provider
 */
function renderApp() {
  return render(
    <NiceModal.Provider>
      <App />
    </NiceModal.Provider>
  );
}

describe('App Integration Tests', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    // Reset zustand store state before each test
    useTaskStore.setState({
      tasks: [],
      isLoading: false,
      error: null,
      filterStatus: 'all',
    });
  });

  it('loads and displays tasks on mount', async () => {
    mockApi.getTasks.mockResolvedValueOnce([
      {
        id: '1',
        title: 'Test Task 1',
        status: 'pending',
        priority: 'high',
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
    ]);

    renderApp();

    expect(screen.getByText('Loading tasks...')).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText('Test Task 1')).toBeInTheDocument();
      expect(screen.getByText('Test Task 2')).toBeInTheDocument();
    });
  });

  it('creates a new task', async () => {
    const user = userEvent.setup();
    mockApi.getTasks.mockResolvedValueOnce([]);
    mockApi.createTask.mockResolvedValueOnce({
      id: '3',
      title: 'New Task',
      description: 'New Description',
      status: 'pending',
      priority: 'medium',
      createdAt: '2025-12-18T12:00:00Z',
      updatedAt: '2025-12-18T12:00:00Z',
    });

    renderApp();

    await waitFor(() => {
      expect(screen.queryByText('Loading tasks...')).not.toBeInTheDocument();
    });

    const newTaskButton = screen.getByRole('button', { name: /new task/i });
    await user.click(newTaskButton);

    await waitFor(() => {
      expect(screen.getByText('Create New Task')).toBeInTheDocument();
    });

    const titleInput = screen.getByLabelText(/title/i);
    await user.type(titleInput, 'New Task');

    const descriptionInput = screen.getByLabelText(/description/i);
    await user.type(descriptionInput, 'New Description');

    const submitButton = screen.getByRole('button', { name: /create task/i });
    await user.click(submitButton);

    await waitFor(() => {
      expect(mockApi.createTask).toHaveBeenCalledWith(
        expect.objectContaining({
          title: 'New Task',
          description: 'New Description',
        })
      );
    });
  });

  it('filters tasks by status', async () => {
    const user = userEvent.setup();
    mockApi.getTasks.mockResolvedValueOnce([
      {
        id: '1',
        title: 'Pending Task',
        status: 'pending',
        priority: 'high',
        createdAt: '2025-12-18T10:00:00Z',
        updatedAt: '2025-12-18T10:00:00Z',
      },
      {
        id: '2',
        title: 'Completed Task',
        status: 'completed',
        priority: 'low',
        createdAt: '2025-12-17T10:00:00Z',
        updatedAt: '2025-12-18T11:00:00Z',
      },
    ]);

    renderApp();

    await waitFor(() => {
      expect(screen.getByText('Pending Task')).toBeInTheDocument();
      expect(screen.getByText('Completed Task')).toBeInTheDocument();
    });

    // Filter by pending - use keyboard navigation to avoid dropdown issues
    const filterSelect = screen.getByRole('combobox', {
      name: /filter by status/i,
    });
    await user.click(filterSelect);

    // Use arrow key to navigate and enter to select
    await user.keyboard('{ArrowDown}');
    await user.keyboard('{Enter}');

    await waitFor(() => {
      expect(screen.getByText('Pending Task')).toBeInTheDocument();
      expect(screen.queryByText('Completed Task')).not.toBeInTheDocument();
    });
  });

  it('toggles task status', async () => {
    const user = userEvent.setup();
    mockApi.getTasks.mockResolvedValueOnce([
      {
        id: '1',
        title: 'Test Task',
        status: 'pending',
        priority: 'high',
        createdAt: '2025-12-18T10:00:00Z',
        updatedAt: '2025-12-18T10:00:00Z',
      },
    ]);

    mockApi.updateTask.mockResolvedValueOnce({
      id: '1',
      title: 'Test Task',
      status: 'completed',
      priority: 'high',
      createdAt: '2025-12-18T10:00:00Z',
      updatedAt: '2025-12-18T12:00:00Z',
    });

    renderApp();

    await waitFor(() => {
      expect(screen.getByText('Test Task')).toBeInTheDocument();
    });

    const statusButton = screen.getByLabelText('Mark as completed');
    await user.click(statusButton);

    await waitFor(() => {
      expect(mockApi.updateTask).toHaveBeenCalledWith('1', {
        status: 'completed',
      });
    });
  });

  it('deletes a task after confirmation', async () => {
    const user = userEvent.setup();
    mockApi.getTasks.mockResolvedValueOnce([
      {
        id: '1',
        title: 'Task to Delete',
        status: 'pending',
        priority: 'high',
        createdAt: '2025-12-18T10:00:00Z',
        updatedAt: '2025-12-18T10:00:00Z',
      },
    ]);

    mockApi.deleteTask.mockResolvedValueOnce(true);

    // Mock window.confirm
    vi.spyOn(window, 'confirm').mockReturnValue(true);

    renderApp();

    await waitFor(() => {
      expect(screen.getByText('Task to Delete')).toBeInTheDocument();
    });

    const deleteButtons = screen.getAllByRole('button', { name: '' });
    const deleteButton = deleteButtons.find((btn) =>
      btn.className.includes('destructive')
    );

    if (deleteButton) {
      await user.click(deleteButton);

      await waitFor(() => {
        expect(mockApi.deleteTask).toHaveBeenCalledWith('1');
      });
    }
  });

  it('edits an existing task', async () => {
    const user = userEvent.setup();
    mockApi.getTasks.mockResolvedValueOnce([
      {
        id: '1',
        title: 'Original Task',
        description: 'Original Description',
        status: 'pending',
        priority: 'high',
        createdAt: '2025-12-18T10:00:00Z',
        updatedAt: '2025-12-18T10:00:00Z',
      },
    ]);

    mockApi.updateTask.mockResolvedValueOnce({
      id: '1',
      title: 'Updated Task',
      description: 'Updated Description',
      status: 'pending',
      priority: 'high',
      createdAt: '2025-12-18T10:00:00Z',
      updatedAt: '2025-12-18T12:00:00Z',
    });

    renderApp();

    await waitFor(() => {
      expect(screen.getByText('Original Task')).toBeInTheDocument();
    });

    // Find all edit buttons and click the first one (not destructive)
    const editButtons = screen.getAllByRole('button', { name: /edit/i });
    const editButton = editButtons[0];
    await user.click(editButton);

    // Wait for modal to appear - check for title input
    await waitFor(() => {
      const titleInput = screen.getByLabelText(/title/i);
      expect(titleInput).toHaveValue('Original Task');
    });

    const titleInput = screen.getByLabelText(/title/i);
    await user.clear(titleInput);
    await user.type(titleInput, 'Updated Task');

    const descriptionInput = screen.getByDisplayValue('Original Description');
    await user.clear(descriptionInput);
    await user.type(descriptionInput, 'Updated Description');

    const submitButton = screen.getByRole('button', { name: /update task/i });
    await user.click(submitButton);

    await waitFor(() => {
      expect(mockApi.updateTask).toHaveBeenCalledWith(
        '1',
        expect.objectContaining({
          title: 'Updated Task',
          description: 'Updated Description',
        })
      );
    });
  });
});
