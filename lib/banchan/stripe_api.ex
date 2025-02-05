defmodule Banchan.StripeAPI do
  @moduledoc """
  Base implementation for Banchan.StripeAPI.Base behavior
  """
  @behaviour Banchan.StripeAPI.Base

  @impl Banchan.StripeAPI.Base
  def create_account(params) do
    Stripe.Account.create(params)
  end

  @impl Banchan.StripeAPI.Base
  def retrieve_account(id) do
    Stripe.Account.retrieve(id)
  end

  @impl Banchan.StripeAPI.Base
  def create_account_link(params) do
    Stripe.AccountLink.create(params)
  end

  @impl Banchan.StripeAPI.Base
  def retrieve_balance(opts \\ []) do
    Stripe.Balance.retrieve(opts)
  end

  @impl Banchan.StripeAPI.Base
  def create_payout(params, opts) do
    Stripe.Payout.create(params, opts)
  end

  @impl Banchan.StripeAPI.Base
  def cancel_payout(id, opts) do
    Stripe.Payout.cancel(id, opts)
  end

  @impl Banchan.StripeAPI.Base
  def create_session(params) do
    Stripe.Session.create(params)
  end

  @impl Banchan.StripeAPI.Base
  def retrieve_payment_intent(intent, params, opts \\ []) do
    Stripe.PaymentIntent.retrieve(intent, params, opts)
  end

  @impl Banchan.StripeAPI.Base
  def retrieve_balance_transaction(id, opts) do
    Stripe.BalanceTransaction.retrieve(id, opts)
  end

  @impl Banchan.StripeAPI.Base
  def expire_payment(session_id) do
    case Stripe.Request.new_request([])
         |> Stripe.Request.put_endpoint("checkout/sessions/#{session_id}/expire")
         |> Stripe.Request.put_method(:post)
         |> Stripe.Request.make_request() do
      {:ok, _} -> :ok
      {:error, err} -> {:error, err}
    end
  end

  @impl Banchan.StripeAPI.Base
  def construct_webhook_event(raw_body, signature, endpoint_secret) do
    Stripe.Webhook.construct_event(raw_body, signature, endpoint_secret)
  end

  @impl Banchan.StripeAPI.Base
  def create_refund(params, opts) do
    Stripe.Refund.create(params, opts)
  end

  @impl Banchan.StripeAPI.Base
  def retrieve_session(id, opts) do
    Stripe.Session.retrieve(id, opts)
  end
end
