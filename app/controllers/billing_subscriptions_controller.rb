# frozen_string_literal: true

# License: AGPL-3.0-or-later WITH Web-Template-Output-Additional-Permission-3.0-or-later
class BillingSubscriptionsController < ApplicationController
  include Controllers::NonprofitHelper

  before_action :authenticate_nonprofit_admin!

  def create_trial
    render JsonResp.new(params) do |_params|
      requires(:nonprofit_id).as_int
      requires(:stripe_plan_id).as_string
    end.when_valid do |params|
      InsertBillingSubscriptions.trial(params[:nonprofit_id], params[:stripe_plan_id])
    end
  end

  def create
    @nonprofit ||= Nonprofit.find(params[:nonprofit_id])
    @subscription = BillingSubscription.create_with_stripe(@nonprofit, params[:billing_subscription])
    json_saved(@subscription, "Success! You are subscribed to #{Settings.general.name}.")
  end

  # post /nonprofits/:nonprofit_id/billing_subscription/cancel
  def cancel
    @result = CancelBillingSubscription.with_stripe(@nonprofit)
    flash[:notice] = "Your subscription has been cancelled. We'll email you soon with exports."
    redirect_to root_url
  end

  # get nonprofits/:nonprofit_id/billing_subscription/cancellation
  def cancellation
    @nonprofit = current_nonprofit
    @billing_plan = @nonprofit.billing_plan
    @billing_subscription = @nonprofit.billing_subscription
  end

  private

  def required_params
    params.permit(:nonprofit_id, :billing_plan_id, :stripe_subscription_id, :status)
  end
end
