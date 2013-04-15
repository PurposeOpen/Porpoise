class Payment::PaypalService
  include Payment::PaymentGateways

  def setup_paypal_donation(amount, currency, donation_classification, return_url, cancel_return_url, remote_ip, recurrent_donation=false)
    amount_in_cents = amount.to_i
    gateway = get_paypal_gateway_for donation_classification

    purchase_description = get_purchase_description(recurrent_donation, amount_in_cents, currency)
     
    order_id = UUID.generate.to_s

    options = {
      :ip => remote_ip,
      :currency => currency.to_s.upcase,
      :return_url => "#{return_url}&order_id=#{order_id}",
      :cancel_return_url => cancel_return_url,
      :no_shipping => 1,
      :order_id => order_id,
      :description => purchase_description,
      :items => [{ :amount => amount_in_cents, :name => purchase_description }]
    }
    if recurrent_donation
      options[:billing_agreement] = {
        :type => 'RecurringPayments',
        :description => purchase_description
      }
    end
    response = gateway.setup_purchase(amount_in_cents, options)

    raise Payment::PaymentError.new(response) unless response.success?

    gateway.redirect_url_for(response.token)
  end

  def complete_paypal_donation(token, payer_id, currency, amount, donation_classification, is_recurring)
    response = do_purchase(donation_classification, amount, currency, payer_id, token, is_recurring)
    raise Payment::PaymentError.new(response) unless response.success?

    transaction_details = {
      :subscription_id => response.params["ProfileID"],
      :transaction_id => response.authorization
    }
  end

  def retrieve_transaction_details(token, donation_classification)
    gateway = get_paypal_gateway_for donation_classification

    transaction_info = gateway.details_for(token)
    {
      :payer_email => transaction_info.email,
      :payer_first_name => transaction_info.info['PayerName']['FirstName'],
      :payer_last_name => transaction_info.info['PayerName']['LastName'],
      :payer_country => transaction_info.payer_country,
      :payer_zip => transaction_info.address['zip'],
      :success => transaction_info.success?
    }
  end

  private

  def do_purchase(donation_classification, amount, currency, payer_id, token, is_recurring)
    amount_in_cents = amount.to_i

    if is_recurring
      # HACK: Need to use ActiveMerchant::Billing::PaypalGateway as ActiveMerchant::Billing::PayPalExpressGateway doesn't include PaypalRecurringApi module. 
      # TODO: Branch gem and add module to gateway class
      gateway = get_credit_card_gateway_for donation_classification
      response = gateway.recurring(amount_in_cents, nil, 
        :period => 'Month',
        :frequency => 1,
        :start_date => Date.today,
        :description => get_purchase_description(is_recurring, amount_in_cents, currency),
        :currency => currency.to_s.upcase,
        :token => token)
    else
      gateway = get_paypal_gateway_for donation_classification
      response = gateway.purchase(amount_in_cents,
        :currency => currency.to_s.upcase,
        :payer_id => payer_id,
        :token => token)
    end

    response
  end

  def get_purchase_description(recurrent_donation, amount_in_cents, currency)
    formatted_amount = Money.new(amount_in_cents, currency).format(:symbol => true)

    I18n.translate(
      recurrent_donation ? 'actions.donations.monthly_donation_message' : 'actions.donations.donation_message', 
      :amount => formatted_amount, :movement_name => Platform.movement_name)
  end
end
