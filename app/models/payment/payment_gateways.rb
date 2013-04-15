require 'active_merchant'

module Payment::PaymentGateways
  CARD_SUCCESS = '1'
  CARD_FAILURE = '2'

  def get_credit_card_gateway_for(donation_classification)
    get_gateway ActiveMerchant::Billing::PaypalGateway, donation_classification
  end

  def get_paypal_gateway_for(donation_classification)
    get_gateway ActiveMerchant::Billing::PaypalExpressGateway, donation_classification
  end

  private

  def get_gateway(gateway_class, classification)
    ActiveMerchant::Billing::Base.gateway_mode = :test if Rails.env.development? || Rails.env.test?

    if Rails.env.test?
      ActiveMerchant::Billing::BogusGateway.new(:test => true)
    else
      credentials = {
        '501(c)3' => {
          :login => ENV["PAYPAL_501C3_API_LOGIN"] || ENV["PAYPAL_API_LOGIN"],
          :password => ENV["PAYPAL_501C3_API_PASSWORD"] || ENV["PAYPAL_API_PASSWORD"],
          :signature => ENV["PAYPAL_501C3_API_SIGNATURE"] || ENV["PAYPAL_API_SIGNATURE"]
        },
        '501(c)4' => {
          :login => ENV["PAYPAL_501C4_API_LOGIN"],
          :password => ENV["PAYPAL_501C4_API_PASSWORD"],
          :signature => ENV["PAYPAL_501C4_API_SIGNATURE"]
        }
      }
      gateway_class.new(credentials[classification.present? ? classification : '501(c)3'])
    end
  end
end
