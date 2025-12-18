import { useEffect, useRef } from 'react';
import Modal from '@ebay/nice-modal-react';
import type { Task, CreateTaskInput } from '~/shared/task/types';
import { useTaskStore, useFilteredTasks } from '~/stores/task-store';
import { TaskList } from '~/features/tasks/list';
import { TaskModal } from '~/features/tasks/modal';
import { TaskFilter } from '~/features/tasks/filter';
import { Button } from '~/components/ui/button';
import { Plus, Loader2, Download, Upload, Wine } from 'lucide-react';
import { ThemeProvider } from '~/contexts/theme-context';
import { ThemeToggle } from '~/components/theme-toggle';
import { api } from '~/services/api';

export function App() {
  const {
    isLoading,
    error,
    fetchTasks,
    createTask,
    updateTask,
    deleteTask,
    toggleStatus,
    filterStatus,
    setFilterStatus,
  } = useTaskStore();
  const filteredTasks = useFilteredTasks();

  useEffect(() => {
    fetchTasks();
  }, [fetchTasks]);

  const handleViewTask = (task: Task) => {
    Modal.show(TaskModal, { mode: 'view', task });
  };

  const handleEditTask = async (task: Task) => {
    try {
      const data = await Modal.show(TaskModal, { mode: 'edit', task });
      if (data) {
        await updateTask(task.id, data as CreateTaskInput);
      }
    } catch {
      // Modal was cancelled
    }
  };

  const handleDeleteTask = async (id: string) => {
    if (!confirm('Are you sure you want to delete this task?')) return;
    await deleteTask(id);
  };

  const handleNewTask = async () => {
    try {
      const data = await Modal.show(TaskModal, { mode: 'create' });
      if (data) {
        await createTask(data as CreateTaskInput);
      }
    } catch {
      // Modal was cancelled
    }
  };

  const handleExport = async () => {
    try {
      await api.exportTasks();
    } catch (err) {
      console.error('Export failed:', err);
    }
  };

  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleImport = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    try {
      const result = await api.importTasks(file);
      await fetchTasks();
      alert(`Import successful: ${result.imported} tasks imported (${result.added} new, ${result.replaced} replaced)`);
    } catch (err) {
      console.error('Import failed:', err);
      alert(`Import failed: ${err instanceof Error ? err.message : 'Unknown error'}`);
    } finally {
      // Reset file input
      if (fileInputRef.current) {
        fileInputRef.current.value = '';
      }
    }
  };

  const handleImportClick = () => {
    fileInputRef.current?.click();
  };

  return (
    <ThemeProvider>
      <div className="min-h-screen bg-background">
        <div className="container max-w-7xl mx-auto py-8 px-4">
          <div className="mb-8 flex justify-between items-start">
            <div className="flex items-center gap-3">
              <Wine className="h-10 w-10 text-purple-600 dark:text-purple-400" />
              <h1 className="text-4xl font-bold tracking-tight">
                Taskana
              </h1>
            </div>
            <ThemeToggle />
          </div>

          {error && (
            <div className="mb-6 p-4 bg-destructive/10 text-destructive rounded-lg">
              {error}
            </div>
          )}

          <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6">
            <TaskFilter value={filterStatus} onChange={setFilterStatus} />
            <div className="flex gap-2">
              <input
                type="file"
                ref={fileInputRef}
                onChange={handleImport}
                accept="application/json,.json"
                className="hidden"
              />
              <Button variant="outline" onClick={handleImportClick}>
                <Upload className="h-4 w-4 mr-2" />
                Import
              </Button>
              <Button variant="outline" onClick={handleExport}>
                <Download className="h-4 w-4 mr-2" />
                Export
              </Button>
              <Button onClick={handleNewTask}>
                <Plus className="h-4 w-4 mr-2" />
                New Task
              </Button>
            </div>
          </div>

          {isLoading ? (
            <div className="flex flex-col items-center justify-center py-12">
              <Loader2 className="h-8 w-8 animate-spin text-primary mb-4" />
              <p className="text-muted-foreground">Loading tasks...</p>
            </div>
          ) : (
            <TaskList
              tasks={filteredTasks}
              onEdit={handleEditTask}
              onDelete={handleDeleteTask}
              onToggleStatus={toggleStatus}
              onView={handleViewTask}
            />
          )}
        </div>
      </div>
    </ThemeProvider>
  );
}

export default App;
