defmodule SdbWeb.Router do
  use SdbWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug SdbWeb.Plugs.EnsureUserId
  end

  scope "/api", SdbWeb do
    pipe_through :api

    get "/tasks/export", TaskController, :export
    resources "/tasks", TaskController, except: [:new, :edit]
  end
end
