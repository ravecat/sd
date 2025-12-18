# Taskany

A task management application built with Elixir/Phoenix backend and React frontend, managed as an Nx monorepo.

## Overview and Key Features

- **Task Management**: Create, read, update, and delete tasks with rich metadata
- **User Isolation**: Each user has completely isolated task storage
- **Import/Export**: Full task data portability with JSON import/export
- **Real-time Updates**: Built on Phoenix channels for live updates
- **Modern UI**: Clean, accessible interface built with Radix UI and Tailwind CSS
- **Type Safety**: Full TypeScript support across the frontend
- **File-based Storage**: Simple JSON file persistence per user (no database required)

### Task Fields

- **Title**: Brief task description
- **Description**: Detailed task information
- **Priority**: low, medium, high
- **Status**: pending, in_progress, completed
- **Due Date**: Optional deadline
- **Timestamps**: Automatic creation and update tracking

## Prerequisites

Before beginning, ensure the following are installed:

- **Node.js** (v20.19.5 or higher)
- **Elixir** (v1.15.7 or higher)
- **Erlang/OTP** (v25 or higher)

or use [asdf](https://asdf-vm.com/) tool version manager with instructions below.

### ASDF Installation (optional, recommended)

The project uses `.tool-versions` to declare required runtimes; `asdf` can install and manage these versions.

1. Install `asdf` for the operating system and follow the official getting [started guide](https://asdf-vm.com/guide/getting-started.html).

2. Install required asdf plugins:

   - Node.js - [asdf-nodejs](https://github.com/asdf-vm/asdf-nodejs.git)
   - pnpm - [asdf-pnpm](https://github.com/jonathanmorley/asdf-pnpm.git)
   - Erlang - [asdf-erlang](https://github.com/asdf-vm/asdf-erlang.git)
   - Elixir - [asdf-elixir](https://github.com/asdf-vm/asdf-elixir.git)

   See the plugin documentation for platform-specific prerequisites and additional usage notes.

3. Install the versions declared in `.tool-versions` by running the following command from the project root (after required plugins are added):

```bash
asdf install
```

**Notes:**

- Building runtimes dependencies may require native dependencies (e.g., C build tools, OpenSSL, zlib). See the plugin documents for OS-specific prerequisites.
- If `asdf` is not used, install required runtimes using the system package manager.

## Setup and Installation

### Initial Setup

```bash
# Install all dependencies
pnpm install

# Setup backend dependencies
cd apps/sdb
mix deps.get
```

## Quick start

This project is a polyglot monorepo managed by [Nx](https://nx.dev) that combines multiple applications.

### Running Applications

```bash
# Start all applications in development mode
pnpm dlx nx run-many -t serve

# Or use interactive UI to select and run targets
pnpm dlx nx run-many -t serve --tui
```

### Manual Startup (Alternative)

If you prefer to start applications separately:

**Backend (Phoenix):**

```bash
cd apps/sdb
mix phx.server
```

The API will be available at `http://localhost:4000`

**Frontend (React):**

```bash
cd apps/sdf
npm run dev
```

The UI will be available at `http://localhost:5173`

## API Documentation

### Authentication

User identification is handled via session management. Each user has isolated task storage.

### Endpoints

#### Tasks

| Method   | Endpoint        | Description                               |
| -------- | --------------- | ----------------------------------------- |
| `GET`    | `/tasks`        | List all tasks for the authenticated user |
| `POST`   | `/tasks`        | Create a new task                         |
| `GET`    | `/tasks/:id`    | Get a specific task by ID                 |
| `PUT`    | `/tasks/:id`    | Update a task                             |
| `DELETE` | `/tasks/:id`    | Delete a task                             |
| `GET`    | `/tasks/export` | Export all tasks as JSON                  |
| `POST`   | `/tasks/import` | Import tasks from JSON file               |

#### Request/Response Format

**Task Object:**

```json
{
  "id": "uuid",
  "title": "Task title",
  "description": "Task description",
  "priority": "low|medium|high",
  "status": "pending|in_progress|completed",
  "dueDate": "2024-01-01T00:00:00Z",
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z"
}
```

**Error Response:**

```json
{
  "errors": ["Error message"]
}
```

### API Usage Examples

```bash
# Get all tasks
curl http://localhost:4000/api/tasks

# Create a task
curl -X POST http://localhost:4000/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "New task", "priority": "high"}'
```

## Scripts and Commands

### Nx Commands

```bash
# Development
pnpm dlx nx serve sdb          # Start backend
pnpm dlx nx serve sdf          # Start frontend
pnpm dlx nx run-many -t serve  # Start all applications

# Building
pnpm dlx nx build sdb          # Build backend
pnpm dlx nx build sdf          # Build frontend

# Testing
pnpm dlx nx test sdb           # Test backend
pnpm dlx nx test sdf           # Test frontend
pnpm dlx nx run-many -t test   # Test all

# Type checking
pnpm dlx nx typecheck sdb      # Type check backend
pnpm dlx nx typecheck sdf      # Type check frontend
```

## Technology Choices, Reasoning, and Trade-offs

### Nx Monorepo

**Why Nx:**

- **Rapid Scaffolding**: Extensive plugin ecosystem for quick code generation
- **Unified Management**: Single repository for multiple applications with shared tooling
- **Dependency Graph**: Intelligent build ordering and affected project detection
- **Code Sharing**: Easy sharing of libraries and utilities across applications

**Trade-offs:**

- **Learning Curve**: Requires understanding Nx concepts and configuration
- **Non-JS Adaptation**: While primarily JS-focused, adapting to Elixir projects requires configuration
- **Build Complexity**: Initial setup is more complex than single-project setups

### Elixir/Phoenix

**Why Phoenix:**

- **Performance**: BEAM VM provides excellent concurrency and fault tolerance
- **Rapid Prototyping**: Generators and scaffolding accelerate development
- **Scalability**: Built to handle growing load with minimal changes
- **Functional Programming**: Immutable state and explicit data flow reduce bugs
- **Hot Code Reload**: Develop without server restarts

**Trade-offs:**

- **Learning Curve**: Functional programming and Elixir syntax require adjustment
- **Ecosystem**: Smaller ecosystem compared to Node.js or Python

### React

**Why React:**

- **Component Model**: Reusable, composable UI components
- **Ecosystem**: Vast library and tool ecosystem
- **Performance**: Efficient rendering with virtual DOM
- **Type Safety**: Excellent TypeScript integration
- **Community**: Large community and extensive documentation

**Trade-offs:**

- **Runtime Dependencies**: Requires JavaScript runtime in the browser
- **Bundle Size**: Can result in larger initial bundle sizes
- **State Management**: Requires careful state management architecture
- **Frequent Updates**: Rapid ecosystem evolution requires maintenance

## Architecture Decisions

### File-based Storage

Using JSON files instead of a traditional database:

- **Pros**: Simple setup, easy backups, no database migrations required
- **Cons**: Not suitable for high-concurrency scenarios, limited querying capabilities

### User Isolation

Each user's tasks are stored in separate files:

- **Pros**: Complete data isolation, simple security model
- **Cons**: Potential file count growth with many users

## License

MIT License - see LICENSE file for details
