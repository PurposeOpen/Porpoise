class Payment::CreditCardPaymentService
  include Payment::PaymentGateways

  def build_credit_card_from(params)
    first_name, *last_names = params[:name_on_card].split
    last_name = last_names.join(" ")

    ActiveMerchant::Billing::CreditCard.new(
      :type => params[:card_type],
      :first_name => first_name,
      :last_name => last_name,
      :number => params[:card_number].gsub(/[^0-9]/, ""),
      :month => params[:card_expiration_month].to_i,
      :year => params[:card_expiration_year].to_i,
      :verification_value => params[:card_cvv2])
  end

  def authorize(currency, amount_in_cents, credit_card, donation_classification, remote_ip)
    gateway = get_credit_card_gateway_for donation_classification
    order_id = UUID.generate.to_s
    response = gateway.purchase(amount_in_cents, credit_card,
        :currency => currency.to_s.upcase,
        :order_id => order_id,
        :ip => remote_ip)

    raise Payment::PaymentError.new(response) unless response.success?

    { :order_id => order_id, :transaction_id => response.authorization }
  end
end