defmodule SdbWeb.Router do
  use SdbWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", SdbWeb do
    pipe_through :api

    resources "/tasks", TaskController, except: [:new, :edit]
  end
end
