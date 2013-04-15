require 'spec_helper'

describe Payment::PaymentGateways do

  class TestPaymentGateways
    include Payment::PaymentGateways
  end

  before do
    Rails.env.stub(:test?).and_return(false)
  end

  it "should use environment variables to create paypal gateway for c3 donations" do
    ENV["PAYPAL_501C3_API_LOGIN"] = 'c3login'
    ENV["PAYPAL_501C3_API_PASSWORD"] = 'c3password'
    ENV["PAYPAL_501C3_API_SIGNATURE"] = 'c3signature'

    ActiveMerchant::Billing::PaypalExpressGateway.should_receive(:new).with(:login => 'c3login', :password => 'c3password', :signature => 'c3signature')

    TestPaymentGateways.new.get_paypal_gateway_for '501(c)3'
  end

  it "should use environment variables to create paypal gateway for c4 donations" do
    ENV["PAYPAL_501C4_API_LOGIN"] = 'c4login'
    ENV["PAYPAL_501C4_API_PASSWORD"] = 'c4password'
    ENV["PAYPAL_501C4_API_SIGNATURE"] = 'c4signature'

    ActiveMerchant::Billing::PaypalExpressGateway.should_receive(:new).with(:login => 'c4login', :password => 'c4password', :signature => 'c4signature')

    TestPaymentGateways.new.get_paypal_gateway_for '501(c)4'
  end

  it "should use environment variables to create credit card gateway for c3 donations" do
    ENV["PAYPAL_501C3_API_LOGIN"] = 'c3login'
    ENV["PAYPAL_501C3_API_PASSWORD"] = 'c3password'
    ENV["PAYPAL_501C3_API_SIGNATURE"] = 'c3signature'

    ActiveMerchant::Billing::PaypalGateway.should_receive(:new).with(:login => 'c3login', :password => 'c3password', :signature => 'c3signature')

    TestPaymentGateways.new.get_credit_card_gateway_for '501(c)3'
  end

  it "should use environment variables to create credit card gateway for c4 donations" do
    ENV["PAYPAL_501C4_API_LOGIN"] = 'c4login'
    ENV["PAYPAL_501C4_API_PASSWORD"] = 'c4password'
    ENV["PAYPAL_501C4_API_SIGNATURE"] = 'c4signature'

    ActiveMerchant::Billing::PaypalGateway.should_receive(:new).with(:login => 'c4login', :password => 'c4password', :signature => 'c4signature')

    TestPaymentGateways.new.get_credit_card_gateway_for '501(c)4'
  end

  it "should treat non classified donation modules as a 501c3 donation" do
    ENV["PAYPAL_501C3_API_LOGIN"] = 'c3login'
    ENV["PAYPAL_501C3_API_PASSWORD"] = 'c3password'
    ENV["PAYPAL_501C3_API_SIGNATURE"] = 'c3signature'

    ActiveMerchant::Billing::PaypalGateway.should_receive(:new).with(:login => 'c3login', :password => 'c3password', :signature => 'c3signature')

    TestPaymentGateways.new.get_credit_card_gateway_for ''
  end
end