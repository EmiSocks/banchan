defmodule BanchanWeb.StudioLive.Index do
  @moduledoc """
  Listing of studios belonging to the current user
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.LiveRedirect

  alias Banchan.Studios
  alias BanchanWeb.Components.{Layout, StudioCard}
  alias BanchanWeb.Endpoint

  @impl true
  def mount(_params, session, socket) do
    socket = assign_defaults(session, socket, false)
    studios = Studios.list_studios()
    {:ok, assign(socket, studios: studios)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <h1 class="title">Studios</h1>
      <div class="studios columns is-multiline">
        {#for studio <- @studios}
          <div class="column is-one-third">
            <StudioCard studio={studio} />
          </div>
        {/for}
      </div>
      <LiveRedirect to={Routes.studio_new_path(Endpoint, :new)}>
        <h2>Create a new studio</h2>
      </LiveRedirect>
    </Layout>
    """
  end
end
