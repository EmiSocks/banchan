# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Banchan.Repo.insert!(%Banchan.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

if Mix.env() == :test do
  Mox.defmock(Banchan.StripeAPI.Mock, for: Banchan.StripeAPI.Base)

  Banchan.StripeAPI.Mock
  |> Mox.expect(:create_account, fn _ ->
    {:ok, %Stripe.Account{id: "mock_account#{System.unique_integer()}"}}
  end)
end

{:ok, user} =
  Banchan.Accounts.register_admin(%{
    handle: "zkat",
    email: "kat@dwg.dev",
    password: "foobarbazquux",
    password_confirmation: "foobarbazquux"
  })

{:ok, _} = Banchan.Repo.transaction(Banchan.Accounts.confirm_user_multi(user))

user = user |> Banchan.Repo.reload()

{:ok, _} =
  Banchan.Notifications.update_user_notification_settings(user, %{
    commission_email: true,
    commission_web: true
  })

{:ok, studio} =
  Banchan.Studios.new_studio(
    %Banchan.Studios.Studio{artists: [user]},
    "https://banchan.art/studios/kitteh-studio",
    %{
      handle: "kitteh-studio",
      name: "Kitteh Studio",
      description: "Kitteh-related stuff",
      summary: """
      ### These are all private commissions, meaning: **non-commercial**

      You're only paying for my service to create the work not copyrights or licensing of the work itself!

      #### I will draw

      * Humans/humanoids
      * anthros+furries/creatures/monsters/animals
      * mecha/robots/vehicles
      * environments/any type of background

      #### I will not draw

      * NSFW
      * Fanart
      """,
      default_terms:
        "I agree that this can **never be used for NFTs** in any way, shape, or form."
    }
  )

{:ok, _} =
  Banchan.Offerings.new_offering(studio, true, %{
    type: "illustration",
    index: 0,
    name: "Illustration",
    description: "A detailed illustration with full rendering and background.",
    open: true,
    hidden: false,
    max_proposals: 3,
    options: [
      %{
        name: "Base Price",
        description: "The commission itself.",
        price: Money.new(10000, :USD),
        default: true,
        sticky: true
      },
      %{
        name: "Extra Character",
        description: "Add another character to the illustration.",
        price: Money.new(500, :USD),
        multiple: true
      },
      %{
        name: "Full background",
        description: "Add full background.",
        price: Money.new(4500, :USD)
      }
    ]
  })

{:ok, _} =
  Banchan.Offerings.new_offering(studio, true, %{
    type: "chibi",
    index: 1,
    name: "Chibi",
    description: "Big eyes, small mouth, tiny body, big heart.",
    open: true,
    hidden: true,
    slots: 3,
    options: [
      %{
        name: "Base Price",
        description: "One chibi character, to order.",
        price: Money.new(5000, :USD),
        default: true,
        sticky: true
      },
      %{
        name: "Extra Character",
        description: "Add an extra character to the commission.",
        price: Money.new(2500, :USD),
        multiple: true
      }
    ],
    terms: "**No NFTs**. But also no derivative works."
  })
