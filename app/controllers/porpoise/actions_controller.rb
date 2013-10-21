module Porpoise
  class ActionsController < ApplicationController
    include RecurlyConfigurationHelper

    remote_resource_class Platform::ActionPage

    after_filter :allow_preview_from_other_domains, only: :preview

    MEMBER_FIELDS_URI = [Platform.base_uri, "#{I18n.locale}/movements/#{Platform.movement_id}/action_pages/"].join(Platform.base_uri.ends_with?("/") ? "" : "/")

    def show
      cookies[:user_language] = I18n.locale
      render_action_page
    end

    def member_fields
      url = URI.join(MEMBER_FIELDS_URI, "#{params[:action_id]}/member_fields.json?email=#{params[:email]}")
      response = open_on_platform(url)
      render :json => JSON.parse(response.as_json.first), :callback => params[:callback]
    end

    def member_info
      data = JSON.parse(get_member_info_from_platform(params[:email]).as_json.first)
      render :json => JSON.parse(data.to_json(:only => ['first_name', 'last_name'])), :callback => params[:callback]
    end

    def get_member_info
      result = get_member_info_from_platform(params[:member_info][:email])
      JSON.parse(result.as_json.first)
    end

    def get_member_info_from_platform(email)
      request_url = "#{Platform.base_uri}movements/#{Platform.movement_id}/members.json?email=#{email}"
      open_on_platform(request_url)
    end

    def preview
      @action_content = Platform::ActionPage.find_preview(params[:id])
      @member = Platform::Member.new
    end

    def take_action
      do_take_action(params)
    end

    def donate_with_credit_card
      action_info = params[:action_info]
      member_info = params[:member_info]


      if(member_info['first_name'].nil?)
        info = get_member_info
        member_info['first_name'] = info['first_name']
        member_info['last_name'] = info['last_name']
      end

      currency = action_info[:currency]
      amount = Money.from_numeric(action_info[:amount].to_f, currency).cents
      is_recurring = (action_info['is_recurring'] == 'true')

      set_recurly_key params[:classification]

      if (is_recurring)
        campaign_id = params[:action_internal_id]
        credit_card_trx_result = perform_credit_card_recurrent_trx(campaign_id, member_info,action_info, currency, amount)
        action_info_to_register = {
            :payment_method => :credit_card,
            :subscription_id => credit_card_trx_result.uuid,
            :transaction_id => credit_card_trx_result.uuid,
            :subscription_amount => amount,
            :currency => currency,
            :frequency => :monthly,
            :confirmed => false
        }
      else
        credit_card_trx_result = perform_credit_card_one_time_trx(member_info,action_info, currency, amount)
        action_info_to_register = {
            :payment_method => :credit_card,
            :currency => currency,
            :amount => amount,
            :order_id => credit_card_trx_result.invoice.invoice_number,
            :transaction_id => credit_card_trx_result.uuid,
            :frequency => :one_off,
            :confirmed => false
        }
      end

      params.delete(:action_info)
      do_take_action(params.merge(:id => params[:id], :action_info => action_info_to_register))

    rescue Payment::DuplicatedSubscriptionError
      flash[:error] = 'duplicated_subscription_error'
      redirect_to action_path(I18n.locale, params[:id])
    rescue Payment::PaymentError => payment_error
      begin
        payment_error_data = {
                      :error_code => payment_error.response[:error_code],
                      :message => "#{payment_error.response[:error_message]}",
                      :donation_payment_method => :recurly,
                      :donation_amount_in_cents => amount,
                      :donation_currency => currency }
        send_paypal_error_to_platform(params[:member_info], payment_error_data)
      ensure
        Rails.logger.error("An error happened on a credit card donation attempt: #{payment_error.response.inspect}")
        flash[:error] = 'credit_card_donation_error'
        redirect_to action_path(I18n.locale, params[:id])
      end
    end

    def perform_credit_card_one_time_trx(member_info,action_info, currency, amount)
      transaction = Recurly::Transaction.create(
          :amount_in_cents => amount,
          :currency        => currency.upcase,
          :account         => {
              :account_code => member_info['email'],
              :billing_info => {
                  :first_name         => member_info['first_name'],
                  :last_name          => member_info['last_name'],
                  :number             => action_info['card_number'],
                  :verification_value => action_info['card_cvv2'],
                  :month              => action_info['card_expiration_month'].to_i,
                  :year               => action_info['card_expiration_year'].to_i
              }
          }
      )
      if(transaction.response.code != '201')
        raise Payment::PaymentError.new({ :error_code => transaction.response.code, :error_message => 'Possible configuration error'})
      end
      transaction
    rescue Recurly::Transaction::DeclinedError => recurly_exception
      raise Payment::PaymentError.new({:error_code => recurly_exception.transaction['transaction_error']['error_code'], :error_message => recurly_exception.transaction['transaction_error']['merchant_message']})
    end

    def perform_credit_card_recurrent_trx(campaign_id, member_info,action_info, currency, amount)
      quantity = amount / 100
      amount = 100
      ensure_plan_exists(campaign_id)
      new_subscription = Recurly::Subscription.create(
          :plan_code => "#{campaign_id}--monthly",
          :currency  => currency.upcase,
          :unit_amount_in_cents => amount,
          :quantity => quantity,
          :account   => {
              :account_code => member_info['email'],
              :email        => member_info['email'],
              :first_name   => member_info['first_name'],
              :last_name    => member_info['last_name'],
              :billing_info => {
                  :first_name         => member_info['first_name'],
                  :last_name          => member_info['last_name'],
                  :number             => action_info['card_number'],
                  :verification_value => action_info['card_cvv2'],
                  :month              => action_info['card_expiration_month'].to_i,
                  :year               => action_info['card_expiration_year'].to_i
              }
          }
      )
      if(new_subscription.response.code != '201')
        if(new_subscription.response.body.include?('already_subscribed'))
          raise Payment::DuplicatedSubscriptionError.new()
        else
          raise Payment::PaymentError.new({:error_code => new_subscription.response.code, :error_message => 'Possible configuration error'})
        end
      end
      new_subscription
    rescue Recurly::Transaction::DeclinedError => recurly_exception
      raise Payment::PaymentError.new({:error_code => recurly_exception.transaction['transaction_error']['error_code'], :error_message => recurly_exception.transaction['transaction_error']['merchant_message']})
    end

    def ensure_plan_exists(campaign_id)
      plan_code = "#{campaign_id}--monthly"
      Recurly::Plan.find(plan_code)
    rescue Exception => e
      plan = Recurly::Plan.create(
          :plan_code            => plan_code,
          :name                 => plan_code,
          :unit_amount_in_cents => { 'USD' => 100, 'EUR' => 100 },
          :setup_fee_in_cents   => { 'USD' => 0, 'EUR' => 0 },
          :plan_interval_length => 1,
          :plan_interval_unit   => 'months'
      )
    end

    def setup_paypal_donation
      action_info = params[:action_info]
      is_recurring = action_info[:is_recurring] == 'true'
      currency = action_info[:currency]
      amount_in_cents = Money.from_numeric(action_info[:amount].to_f, currency).cents
      donation_classification = params[:classification]

      cancel_return_url = action_url(I18n.locale, params[:id])
      return_url = return_from_paypal_action_url(I18n.locale, params[:id],
                                                 :currency => currency,
                                                 :amount => amount_in_cents,
                                                 :classification => donation_classification,
                                                 :t => params[:t],
                                                 :is_recurring => is_recurring)

      paypal_redirect_url = Payment::PaypalService.new.setup_paypal_donation(amount_in_cents, currency,
                                                                             donation_classification, return_url, cancel_return_url, request.remote_ip, is_recurring)

      redirect_to paypal_redirect_url
    rescue Payment::PaymentError => payment_error
      Rails.logger.error("An error happened setting up a paypal donation: #{payment_error.response.inspect}")
      render_action_page('paypal_initialization_error')
    end

    def return_from_paypal
      @token = params[:token]
      @PayerID = params[:PayerID]
      @currency = params[:currency]
      @amount = params[:amount]
      @order_id = params[:order_id]
      @classification = params[:classification]
      @is_recurring = params[:is_recurring]
      @t = params[:t]
      @id = params[:id]

      render 'actions/donations/return_from_paypal'
    end

    def complete_paypal_donation
      is_recurring = (params['is_recurring'] == 'true')

      result = Payment::PaypalService.new.complete_paypal_donation(params[:token],
                                                                   params[:PayerID],
                                                                   params[:currency],
                                                                   params[:amount],
                                                                   params[:classification],
                                                                   is_recurring)

      if (is_recurring)
        action_info_to_register = {
          :payment_method => :paypal,
          :subscription_id => result[:subscription_id],
          :subscription_amount => params[:amount],
          :currency => params[:currency],
          :frequency => :monthly,
          :confirmed => false
        }
      else
        action_info_to_register = {
          :payment_method => :paypal, 
          :frequency => :one_off,
          :currency => params[:currency], 
          :amount => params[:amount], 
          :order_id => params[:order_id], 
          :transaction_id => result[:transaction_id],
          :confirmed => false
        }
      end

      do_take_action(params.merge(:action_info => action_info_to_register))
    rescue Payment::PaymentError => payment_error
      Rails.logger.error("An error happened on a PayPal Express donation attempt: #{payment_error.response.inspect}")

      begin
        member_info = retrieve_member_info_from_paypal(params[:token], params[:classification])
        payment_error_data = { :error_code => payment_error.response.params['error_codes'], :message => "#{payment_error.response.message}\nAVS:\n#{payment_error.response.avs_result.to_yaml}\nCVV:\n#{payment_error.response.cvv_result.to_yaml}", :donation_payment_method => :paypal, :donation_amount_in_cents => params[:amount], :donation_currency => params[:currency] }
        send_paypal_error_to_platform(member_info, payment_error_data)
      ensure
        render_action_page('donation_information_error')
      end
    end

    protected

    def retrieve_member_info_from_paypal(token, donation_classification)
      member_info = {}
      transaction_info = Payment::PaypalService.new.retrieve_transaction_details(token, donation_classification)

      member_info = {
        :email => transaction_info[:payer_email],
        :first_name => transaction_info[:payer_first_name],
        :last_name => transaction_info[:payer_last_name],
        :country_iso => transaction_info[:payer_country],
        :postcode => transaction_info[:payer_zip]
      } if transaction_info[:success]

    rescue StandardError => error
      Rails.logger.error("An error happened while attempting to retrieve transaction info for token: #{token}")
    ensure
      return member_info
    end

    def send_paypal_error_to_platform(member_info, payment_error_data)
      payment_error_uri = "#{Platform.base_uri}movements/#{Platform.movement_id}/action_pages/#{params[:id]}/donation_payment_error"

      # Net::Http::Post.form_data doesn't support nested hashes (http://apidock.com/ruby/Net/HTTPHeader/set_form_data)
      form_data = member_info.map { |k, v| { "member_info[#{k}]" => v } }.inject({}) {|memo, obj| memo.merge(obj) }
      form_data.merge!(payment_error_data.map { |k,v| { "payment_error_data[#{k}]" => v } }.inject({}) {|memo, obj| memo.merge(obj) })

      post_to_platform(payment_error_uri, form_data)
    end

    def do_take_action(params)
      @action_content = Platform::ActionPage.find(params[:id], :params => {:locale => I18n.locale})
      platform_response = @action_content.post :take_action, params.slice(:id, :t, :member_info, :action_info).merge(
        :movement_id => Platform.movement_id,
        :locale => I18n.locale
      )

      json_response = JSON.parse(platform_response.body)

      if platform_response.code.to_i == 201
        session[:member_id] = json_response['member_id'] if json_response['member_id'].present?
        next_page_identifier = json_response['next_page_identifier']
        redirect_to next_page_identifier.present? ? action_path(I18n.locale, next_page_identifier) : root_path
      else
        render_action_page(json_response['error'])
      end
    end

    #TODO: report page_not_available errors, don't die silently and then cache over the action
    def render_action_page(error_message = nil)
      action_params = {} #{:locale => I18n.locale}
      params[:email].present? ? action_params.merge!(member_has_joined: true) : nil 
    
      @action_content ||= Platform::ActionPage.find(params[:id], :params=>action_params)
      @member = Platform::Member.new(params[:member_info] || {})
      @member.email = params[:email] if params[:email]

      flash[:error] = error_message unless error_message.nil?
      render :show
    rescue ActiveResource::ClientError => error
      error.response.code.to_i == 406 ? render(:page_not_available) : raise(error)
    end

  end
end
