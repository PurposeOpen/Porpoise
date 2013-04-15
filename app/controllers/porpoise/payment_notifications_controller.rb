require 'nokogiri'
require 'active_merchant'

module Porpoise
  class PaymentNotificationsController < ActionController::Base
    include PlatformCommunicationHelper
    include RecurlyConfigurationHelper

    skip_before_filter :verify_authenticity_token

    def create
      Rails.logger.info("Push notification received from Recurly")
      set_recurly_key params[:classification]

      xml = Nokogiri::XML(request.body.read)

      if(xml.xpath('//successful_payment_notification').count > 0)
        result = self.handle_successful_payment(xml)
      end

      if(xml.xpath('//failed_payment_notification').count > 0)
        result = self.handle_failed_payment(xml)
      end

      if(result && result.code != '200' )
        Rails.logger.error("An error happened when processing a payment notification from Recurly: #{result.code}, #{result.message}")
        render :nothing => true, :status => result.code
      else
        render :nothing => true
      end

    end

    def create_from_paypal
      Rails.logger.info("Push notification received from PayPal")
      
      notification = ActiveMerchant::Billing::Integrations::Paypal::Notification.new(request.raw_post)

      if notification.type =~ /^recurring_payment$/i
        result = handle_successful_recurring_payment_from_pay_pal notification
      elsif notification.type =~ /^(recurring_payment_failed|recurring_payment_skipped)$/i
        result = handle_failed_payment_from_pay_pal notification
      elsif notification.type =~ /^express_checkout$/i
        result = handle_successful_one_time_payment_from_pay_pal notification
      else
        Rails.logger.info("Ignoring notification from PayPal: #{notification.inspect}")
      end

      if (result && result.code != '200')
        Rails.logger.error("An error happened when processing a payment notification from PayPal: #{result.code}, #{result.message}")
        render :nothing => true, :status => result.code
      else
        notification.acknowledge
        render :nothing => true
      end
    rescue Exception => e
      Rails.logger.error("An error happened when processing a payment notification from PayPal: #{e}")
      render :nothing => true, :status => 500
    end

    def handle_failed_payment(xml)
      subscription_id = xml.xpath('//transaction//subscription_id').text
      transaction_id = xml.xpath('//transaction//id').text
      amount = xml.xpath('//transaction//amount_in_cents').text.to_i
      reference = xml.xpath('//transaction//reference').text
      member_email = xml.xpath('//account//account_code').text
      message = xml.xpath('//transaction//message').text
      error_code = xml.xpath('//transaction//status').text

      subscription = Recurly::Subscription::find(subscription_id)
      action_page = subscription.plan.plan_code.split("--")[0]

      payment_error_data = {
          :error_code => error_code,
          :message => message,
          :donation_amount_in_cents => amount,
          :reference => reference,
          :member_email => member_email,
          :subscription_id => subscription_id,
          :transaction_id => transaction_id,
          :action_page => action_page
      }

      payment_error_url = "#{Platform.base_uri}movements/#{Platform.movement_id}/donations/handle_failed_payment"

      post_to_platform(payment_error_url, payment_error_data)
    end

    def handle_failed_payment_from_pay_pal(notification)
      subscription_id = notification.params["recurring_payment_id"]
      donation = Platform::Donation.find(:first, :params => {:subscription_id => subscription_id})

      amount_in_cents = (notification.params["amount"] || 0).to_i * 100

      payment_error_data = {
        :donation_amount_in_cents => amount_in_cents,
        :member_email => donation.user.email,
        :subscription_id => subscription_id,
        :action_page => donation.action_page
      }

      payment_error_url = "#{Platform.base_uri}movements/#{Platform.movement_id}/donations/handle_failed_payment"

      post_to_platform(payment_error_url, payment_error_data)
    end

    def handle_successful_payment(xml)
      subscription_id = xml.xpath('//transaction//subscription_id').text

      if (subscription_id.empty?)
        result = notify_payment_confirmation(xml.xpath('//transaction//id').text)
      else
        transaction_id = xml.xpath('//transaction//id').text
        invoice_number = xml.xpath('//invoice_number').text
        amount_in_cents = xml.xpath('//amount_in_cents').text.to_i
        result = notify_new_payment(subscription_id, transaction_id, invoice_number,amount_in_cents)
      end
      result
    end

    def handle_successful_one_time_payment_from_pay_pal(notification)
      payment_notification_url = "#{Platform.base_uri}movements/#{Platform.movement_id}/donations/confirm_payment"
      result = post_to_platform(payment_notification_url, :transaction_id => notification.params["txn_id"])

      result
    end

    def handle_successful_recurring_payment_from_pay_pal(notification)
      amount_in_cents = (notification.params["amount"] || 0).to_i * 100
      notify_new_payment(notification.params["recurring_payment_id"], notification.params["txn_id"], notification.params["rp_invoice_id"], amount_in_cents)
    end

    def notify_payment_confirmation(transaction_id)
      data_to_notify = {
          :transaction_id => transaction_id,
      }

      Rails.logger.info("calling the platform")
      payment_notification_url = "#{Platform.base_uri}movements/#{Platform.movement_id}/donations/confirm_payment"
      result = post_to_platform(payment_notification_url , data_to_notify)
      Rails.logger.info("platform called")

      result
    end

    def notify_new_payment(subscription_id, transaction_id, invoice_number, amount_in_cents)

      data_to_notify = {
          :subscription_id => subscription_id,
          :transaction_id => transaction_id,
          :order_number => invoice_number,
          :amount_in_cents => amount_in_cents,
      }

      payment_notification_url = "#{Platform.base_uri}movements/#{Platform.movement_id}/donations/add_payment"
      post_to_platform(payment_notification_url, data_to_notify)
    end

  end
end