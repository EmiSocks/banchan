defmodule Banchan.Offerings.Notifications do
  @moduledoc """
  Notifications related to offerings (new slots opening, etc.)
  """
  import Ecto.Query, warn: false

  alias Banchan.Accounts.User
  alias Banchan.Notifications
  alias Banchan.Repo
  alias Banchan.Offerings.{Offering, OfferingSubscription}
  alias Banchan.Studios.StudioFollower

  # Unfortunate, but needed for crafting URLs for notifications
  alias BanchanWeb.Endpoint
  alias BanchanWeb.Router.Helpers, as: Routes

  def user_subscribed?(%User{} = user, %Offering{} = offering) do
    # Intentionally does not check for Studio-level subscriptions.
    # TODO: maybe this _should_ check for studio-level subs, like commissions do?
    from(sub in OfferingSubscription,
      where: sub.user_id == ^user.id and sub.offering_id == ^offering.id and sub.silenced != true
    )
    |> Repo.exists?()
  end

  def subscribe_user!(%User{} = user, %Offering{} = offering) do
    %OfferingSubscription{user_id: user.id, offering_id: offering.id, silenced: false}
    |> Repo.insert(
      on_conflict: {:replace, [:silenced]},
      conflict_target: [:user_id, :offering_id]
    )
  end

  def unsubscribe_user!(%User{} = user, %Offering{} = offering) do
    %OfferingSubscription{user_id: user.id, offering_id: offering.id, silenced: true}
    |> Repo.insert(
      on_conflict: {:replace, [:silenced]},
      conflict_target: [:user_id, :offering_id]
    )
  end

  def subscribers(%Offering{} = offering) do
    from(
      u in User,
      left_join: offering_sub in OfferingSubscription,
      on: offering_sub.offering_id == ^offering.id and u.id == offering_sub.user_id,
      left_join: studio_sub in StudioFollower,
      on: studio_sub.studio_id == ^offering.studio_id and u.id == studio_sub.user_id,
      left_join: settings in assoc(u, :notification_settings),
      where:
        (not is_nil(offering_sub.id) and offering_sub.silenced != true) or
          not is_nil(studio_sub.id),
      distinct: u.id,
      select: %User{
        id: u.id,
        email: u.email,
        notification_settings: settings
      }
    )
    |> Repo.stream()
  end

  def offering_opened(%Offering{} = offering, actor \\ nil) do
    Notifications.with_task(fn ->
      {:ok, _} =
        Repo.transaction(fn ->
          subs = subscribers(offering)

          studio = Repo.preload(offering, :studio).studio

          url =
            Routes.studio_commissions_new_url(
              Endpoint,
              :new,
              studio.handle,
              offering.type
            )

          {:safe, safe_url} = Phoenix.HTML.html_escape(url)

          Notifications.notify_subscribers!(
            actor,
            subs,
            %Notifications.UserNotification{
              type: "offering_open",
              title: "Commission slots now available!",
              short_body:
                "Commission slots are now available for '#{offering.name}' from #{studio.name}.",
              text_body:
                "Commission slots are now available for '#{offering.name}' from #{studio.name}.\n\n#{url}",
              html_body:
                "<p>Commission slots are now available for '#{offering.name}' from #{studio.name}.</p><p><a href=\"#{safe_url}\">View it</a></p>",
              url: url,
              read: false
            }
          )
        end)
    end)
  end
end
