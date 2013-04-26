# Encoding: utf-8
require 'spec_helper'

describe PaymentNotificationsController do

  describe "Recurly notification" do
    describe "create" do

      it "should not fail if unknown_notification arrives" do

        @request.env['RAW_POST_DATA'] = '<?xml version="1.0" encoding="UTF-8"?><unknown_notification></unknown_notification>'

        post :create, { :classification => '501(c)3' }
        @request.env.delete('RAW_POST_DATA')

        response.code.should == '200'
      end

      context "successful payment" do
        it "should confirm payment on platform when receives a Successful_Payment notification corresponding to one-time donation" do

          @request.env['RAW_POST_DATA'] = <<-XML
            <?xml version="1.0" encoding="UTF-8"?>
            <successful_payment_notification>
              <account>
                <account_code>1</account_code>
                <username nil="true">verena</username>
                <email>verena@example.com</email>
                <first_name>Verena</first_name>
                <last_name>Example</last_name>
                <company_name nil="true">Company, Inc.</company_name>
              </account>
              <transaction>
                <id>a5143c1d3a6f4a8287d0e2cc1d4c0427</id>
                <invoice_id>1974a09kj90s0789dsf099798326881c</invoice_id>
                <invoice_number type="integer">2059</invoice_number>
                <subscription_id nil="true"></subscription_id>
                <action>purchase</action>
                <date type="datetime">2009-11-22T13:10:38Z</date>
                <amount_in_cents type="integer">1000</amount_in_cents>
                <status>Success</status>
                <message>Bogus Gateway: Forced success</message>
                <reference></reference>
                <cvv_result code=""></cvv_result>
                <avs_result code=""></avs_result>
                <avs_result_street></avs_result_street>
                <avs_result_postal></avs_result_postal>
                <test type="boolean">true</test>
                <voidable type="boolean">true</voidable>
                <refundable type="boolean">true</refundable>
              </transaction>
            </successful_payment_notification>
          XML

          platform_post_url = 'http://testmovement:testmovement@example.com/api/movements/testmovement/donations/confirm_payment'
          FakeWeb.register_uri :post, platform_post_url, :parameters => {:transaction_id => 'a5143c1d3a6f4a8287d0e2cc1d4c0427'}

          post :create, { :classification => '501(c)3' }
          @request.env.delete('RAW_POST_DATA')
        end

        it "should add payment on platform when receives a Successful_Payment notification corresponding to recurrent donation" do

          @request.env['RAW_POST_DATA'] = <<-XML
            <?xml version="1.0" encoding="UTF-8"?>
            <successful_payment_notification>
              <account>
                <account_code>1</account_code>
                <username nil="true">verena</username>
                <email>verena@example.com</email>
                <first_name>Verena</first_name>
                <last_name>Example</last_name>
                <company_name nil="true">Company, Inc.</company_name>
              </account>
              <transaction>
                <id>a5143c1d3a6f4a8287d0e2cc1d4c0427</id>
                <invoice_id>1974a09kj90s0789dsf099798326881c</invoice_id>
                <invoice_number type="integer">2059</invoice_number>
                <subscription_id>21312313980wsh45345hgh5456</subscription_id>
                <action>purchase</action>
                <date type="datetime">2009-11-22T13:10:38Z</date>
                <amount_in_cents type="integer">1000</amount_in_cents>
                <status>Success</status>
                <message>Bogus Gateway: Forced success</message>
                <reference></reference>
                <cvv_result code=""></cvv_result>
                <avs_result code=""></avs_result>
                <avs_result_street></avs_result_street>
                <avs_result_postal></avs_result_postal>
                <test type="boolean">true</test>
                <voidable type="boolean">true</voidable>
                <refundable type="boolean">true</refundable>
              </transaction>
            </successful_payment_notification>
          XML

          platform_post_url = 'http://testmovement:testmovement@example.com/api/movements/testmovement/donations/add_payment'
          FakeWeb.register_uri :post, platform_post_url,
                               :parameters => {
                                   :subscription_id => '21312313980wsh45345hgh5456',
                                   :transaction_id => 'a5143c1d3a6f4a8287d0e2cc1d4c0427',
                                   :order_number => 2059,
                                   :amount => 1000
                                  }

          post :create, { :classification => '501(c)3' }
          @request.env.delete('RAW_POST_DATA')

        end
      end

      describe "failed payment" do
        it "should notify the platform when receives a Failed_Payment notification from C3 account" do
          @request.env['RAW_POST_DATA'] = <<-XML
            <?xml version="1.0" encoding="UTF-8"?>
            <failed_payment_notification>
              <account>
                <account_code>john.doe@example</account_code>
                <username></username>
                <email>john.doe@example</email>
                <first_name>Nicolas (gmail)</first_name>
                <last_name>Paez</last_name>
                <company_name></company_name>
              </account>
              <transaction>
                <id>1d940c370adf22dce864544e0b85b79e</id>
                <invoice_id>1d940c36ee97ba813109b34b3fa94952</invoice_id>
                <invoice_number type="integer">1058</invoice_number>
                <subscription_id>1234567</subscription_id>
                <action>purchase</action>
                <date type="datetime">2013-01-10T16:18:00Z</date>
                <amount_in_cents type="integer">2000</amount_in_cents>
                <status>declined</status>
                <message>Declined transaction</message>
                <reference>6148564</reference>
                <source>transaction</source>
                <cvv_result code=""></cvv_result>
                <avs_result code=""></avs_result>
                <avs_result_street nil="true"></avs_result_street>
                <avs_result_postal nil="true"></avs_result_postal>
                <test type="boolean">true</test>
                <voidable type="boolean">false</voidable>
                <refundable type="boolean">false</refundable>
              </transaction>
            </failed_payment_notification>
          XML

          params = {
              :error_code => 'declined',
              :message => 'Declined transaction',
              :donation_amount_in_cents => 2000,
              :reference => '6148564',
              :member_email => 'john.doe@example',
              :subscription_id => '1234567',
              :transaction_id => '1d940c370adf22dce864544e0b85b79e',
              :action_page => 'testplan',
          }
          platform_post_url = "http://testmovement:testmovement@example.com/api/movements/testmovement/donations/handle_failed_payment"
          FakeWeb.register_uri :post, platform_post_url, :parameters => params

          ENV["501C3_RECURLY_KEY"] = 'C3 Recurly account API key'
          Recurly.should_receive(:api_key=).with('C3 Recurly account API key')

          subscription = OpenStruct.new
          subscription.plan = OpenStruct.new
          subscription.plan.plan_code = 'testplan--monthly'
          Recurly::Subscription.should_receive(:find).with('1234567').and_return(subscription)

          post :create, { :classification => '501(c)3' }
          @request.env.delete('RAW_POST_DATA')
        end

        it "should notify the platform when receives a Failed_Payment notification from C4 account" do
          @request.env['RAW_POST_DATA'] = <<-XML
            <?xml version="1.0" encoding="UTF-8"?>
            <failed_payment_notification>
              <account>
                <account_code>john.doe@example</account_code>
                <username></username>
                <email>john.doe@example</email>
                <first_name>Nicolas (gmail)</first_name>
                <last_name>Paez</last_name>
                <company_name></company_name>
              </account>
              <transaction>
                <id>1d940c370adf22dce864544e0b85b79e</id>
                <invoice_id>1d940c36ee97ba813109b34b3fa94952</invoice_id>
                <invoice_number type="integer">1058</invoice_number>
                <subscription_id>1234567</subscription_id>
                <action>purchase</action>
                <date type="datetime">2013-01-10T16:18:00Z</date>
                <amount_in_cents type="integer">2000</amount_in_cents>
                <status>declined</status>
                <message>Declined transaction</message>
                <reference>6148564</reference>
                <source>transaction</source>
                <cvv_result code=""></cvv_result>
                <avs_result code=""></avs_result>
                <avs_result_street nil="true"></avs_result_street>
                <avs_result_postal nil="true"></avs_result_postal>
                <test type="boolean">true</test>
                <voidable type="boolean">false</voidable>
                <refundable type="boolean">false</refundable>
              </transaction>
            </failed_payment_notification>
          XML

          params = {
              :error_code => 'declined',
              :message => 'Declined transaction',
              :donation_amount_in_cents => 2000,
              :reference => '6148564',
              :member_email => 'john.doe@example',
              :subscription_id => '1234567',
              :transaction_id => '1d940c370adf22dce864544e0b85b79e',
              :action_page => 'testplan',
          }
          platform_post_url = "http://testmovement:testmovement@example.com/api/movements/testmovement/donations/handle_failed_payment"
          FakeWeb.register_uri :post, platform_post_url, :parameters => params

          ENV["501C4_RECURLY_KEY"] = 'C4 Recurly account API key'
          Recurly.should_receive(:api_key=).with('C4 Recurly account API key')

          subscription = OpenStruct.new
          subscription.plan = OpenStruct.new
          subscription.plan.plan_code = 'testplan--monthly'
          Recurly::Subscription.should_receive(:find).with('1234567').and_return(subscription)

          post :create, { :classification => '501(c)4' }
          @request.env.delete('RAW_POST_DATA')
        end

        it "should fail if call to the platform fails" do
          @request.env['RAW_POST_DATA'] = <<-XML
            <?xml version="1.0" encoding="UTF-8"?>
            <failed_payment_notification>
              <account>
                <account_code>john.doe@example</account_code>
                <username></username>
                <email>john.doe@example</email>
                <first_name>Nicolas (gmail)</first_name>
                <last_name>Paez</last_name>
                <company_name></company_name>
              </account>
              <transaction>
                <id>1d940c370adf22dce864544e0b85b79e</id>
                <invoice_id>1d940c36ee97ba813109b34b3fa94952</invoice_id>
                <invoice_number type="integer">1058</invoice_number>
                <subscription_id>1234567</subscription_id>
                <action>purchase</action>
                <date type="datetime">2013-01-10T16:18:00Z</date>
                <amount_in_cents type="integer">2000</amount_in_cents>
                <status>declined</status>
                <message>Declined transaction</message>
                <reference>6148564</reference>
                <source>transaction</source>
                <cvv_result code=""></cvv_result>
                <avs_result code=""></avs_result>
                <avs_result_street nil="true"></avs_result_street>
                <avs_result_postal nil="true"></avs_result_postal>
                <test type="boolean">true</test>
                <voidable type="boolean">false</voidable>
                <refundable type="boolean">false</refundable>
              </transaction>
            </failed_payment_notification>
          XML

          params = {
              :error_code => 'declined',
              :message => 'Declined transaction',
              :donation_amount_in_cents => 2000,
              :reference => '6148564',
              :member_email => 'john.doe@example',
              :subscription_id => '1234567',
              :transaction_id => '1d940c370adf22dce864544e0b85b79e',
              :action_page => 'testplan',
          }
          platform_post_url = "http://testmovement:testmovement@example.com/api/movements/testmovement/donations/handle_failed_payment"
          FakeWeb.register_uri :post, platform_post_url, :parameters => params, :status => [500, 'Internal Server Error']

          subscription = OpenStruct.new
          subscription.plan = OpenStruct.new
          subscription.plan.plan_code = 'testplan--monthly'
          Recurly::Subscription.should_receive(:find).with('1234567').and_return(subscription)

          post :create, { :classification => '501(c)3' }
          @request.env.delete('RAW_POST_DATA')

        end
      end
    end
  end

  describe "PayPal notification" do
    describe "create" do
      it "should not fail if unknown_notification arrives" do
        ActiveMerchant::Billing::Integrations::Paypal::Notification.any_instance.should_receive(:acknowledge)

        @request.env['RAW_POST_DATA'] = 'transaction_subject=Donation of 1,00 € to AllOut.org&payment_date=00:00:00 Feb 01, 2013 PST&txn_type=express_checkout&last_name=doe&residence_country=AR&item_name=Donation of 1,00 € to AllOut.org&payment_gross=&mc_currency=EUR&payment_type=instant&protection_eligibility=Ineligible&verify_sign=ABCDE123456&payer_status=verified&tax=0.00&payer_email=john.doe@example.com&txn_id=9999ABCDE9999&quantity=1&receiver_email=admin@allout.org&first_name=john&invoice=aaaaaaaa-bbbb-cccc-dddd-11111111111&payer_id=abc1234&receiver_id=SARASA1234&item_number=&handling_amount=0.00&payment_status=Completed&payment_fee=&mc_fee=1.15&shipping=0.00&mc_gross=25.00&custom=&charset=windows-1252&notify_version=3.7&ipn_track_id=aaabcde1234'

        post :create_from_paypal, { :classification => '501(c)3' }
        @request.env.delete('RAW_POST_DATA')

        response.code.should == '200'
      end

      it "should not acknowledge if exception is raised" do
        @request.env['RAW_POST_DATA'] = 'transaction_subject=Donation of 1,00 € to AllOut.org&payment_date=00:00:00 Feb 01, 2013 PST&txn_type=express_checkout&last_name=doe&residence_country=AR&item_name=Donation of 1,00 € to AllOut.org&payment_gross=&mc_currency=EUR&payment_type=instant&protection_eligibility=Ineligible&verify_sign=ABCDE123456&payer_status=verified&tax=0.00&payer_email=john.doe@example.com&txn_id=9999ABCDE9999&quantity=1&receiver_email=admin@allout.org&first_name=john&invoice=aaaaaaaa-bbbb-cccc-dddd-11111111111&payer_id=abc1234&receiver_id=SARASA1234&item_number=&handling_amount=0.00&payment_status=Completed&payment_fee=&mc_fee=1.15&shipping=0.00&mc_gross=25.00&custom=&charset=windows-1252&notify_version=3.7&ipn_track_id=aaabcde1234'
        
        notification_mock = double
        notification_mock.stub(:type).and_raise(StandardError.new)
        notification_mock.should_not_receive(:acknowledge)
        ActiveMerchant::Billing::Integrations::Paypal::Notification.should_receive(:new).and_return(notification_mock)

        post :create_from_paypal, { :classification => '501(c)3' }
        @request.env.delete('RAW_POST_DATA')

        response.code.should == '500'
      end

      context "successful one-time payment" do
        it "should notify platform when receives successful payment notification corresponding to one-time donation" do
          ActiveMerchant::Billing::Integrations::Paypal::Notification.any_instance.should_receive(:acknowledge)
          transaction_id = '6QQ63319F55AF4123'
          @request.env['RAW_POST_DATA'] = "mc_gross=10.00&invoice=877f7d60-537f-0130-4009-12313d1c9506&protection_eligibility=Eligible&address_status=confirmed&payer_id=BM4HX2RZYSBUA&tax=0.00&address_street=1 Main St&payment_date=10:10:56 Feb 07, 2013 PST&payment_status=Completed&charset=windows-1252&address_zip=95131&first_name=John&mc_fee=29.27&address_country_code=US&address_name=John Doe&notify_version=3.7&custom=&payer_status=verified&address_country=United States&address_city=San Jose&quantity=1&verify_sign=AFcWxV21C7fd0v3bYYYRCpSSRl31AQJQTqsedNRqekhQf1kSfJVHiqD4&payer_email=johnd_1353591860_per@gmail.com&txn_id=#{transaction_id}&payment_type=instant&last_name=Doe&address_state=CA&receiver_email=allout_1353591496_biz@gmail.com&payment_fee=29.27&receiver_id=52WWK6WA8NTCE&txn_type=express_checkout&item_name=Donation of $10.00 to Allout.&mc_currency=USD&item_number=&residence_country=US&test_ipn=1&handling_amount=0.00&transaction_subject=Donation of $10.00 to Allout.&payment_gross=10.00&shipping=0.00&ipn_track_id=60176f63de897"
        
          platform_post_url = 'http://testmovement:testmovement@example.com/api/movements/testmovement/donations/confirm_payment'
          FakeWeb.register_uri :post, platform_post_url, :parameters => {:transaction_id => transaction_id}

          post :create_from_paypal, { :classification => '501(c)3' }
          @request.env.delete('RAW_POST_DATA')

          response.code.should == '200'
          FakeWeb.last_request.path.should match /\/api\/movements\/testmovement\/donations\/confirm_payment/
        end
      end

      context "successful recurrent payment" do
        it "should notify platform when receives successful payment notification corresponding to recurrent donation" do
          subscription_id = "I-LL3IC9BB711M"
          ActiveMerchant::Billing::Integrations::Paypal::Notification.any_instance.should_receive(:acknowledge)

          @request.env['RAW_POST_DATA'] = 'mc_gross=50.00&period_type= Regular&outstanding_balance=0.00&next_payment_date=00:00:00 Mar 01, 2013 PST&protection_eligibility=Ineligible&payment_cycle=Monthly&tax=0.00&payer_id=1TLLMJP9PWL0E&payment_date=00:00:00 Feb 01, 2013 PST&payment_status=Completed&product_name=Monthly donation of £50.00 to AllOut.org&charset=windows-1252&rp_invoice_id=9944b730-50c6-0130-4651-22000a8eeeec&recurring_payment_id=#{subscription_id}&first_name=John&mc_fee=1.83&notify_version=3.7&amount_per_cycle=50.00&payer_status=unverified&currency_code=GBP&business=admin@allout.org&verify_sign=A99UBn.jdKHar60IJmHG2niLzQ4KAM2yA3Y6927Offn329AH3-eeOaKC&initial_payment_amount=0.00&profile_status=Active&amount=50.00&txn_id=9999ABCDE9999&payment_type=instant&last_name=Doe&receiver_email=admin@allout.org&payment_fee=&receiver_id=SARASA1234&txn_type=recurring_payment&mc_currency=GBP&residence_country=GB&receipt_id=3999-1111-2222-3333&transaction_subject=&payment_gross=&shipping=0.00&product_type=1&time_created=00:00:00 Feb 01, 2013 PST&ipn_track_id=a097b45150e33'

          platform_post_url = 'http://testmovement:testmovement@example.com/api/movements/testmovement/donations/add_payment'
          FakeWeb.register_uri :post, platform_post_url,
                               :parameters => {
                                   :subscription_id => subscription_id,
                                   :transaction_id => '9999ABCDE9999',
                                   :order_number => '9944b730-50c6-0130-4651-22000a8eeeec',
                                   :amount => 5000
                                  }

          post :create_from_paypal, { :classification => '501(c)3' }
          @request.env.delete('RAW_POST_DATA')

          response.code.should == '200'
          FakeWeb.last_request.path.should match /\/api\/movements\/testmovement\/donations\/add_payment/
        end
      end

      context "failed payment" do
        it "should notify the platform when receives a failed payment notification" do
          subscription_id = "I-LL3IC9BB711M"
          @request.env['RAW_POST_DATA'] = "payment_cycle=Monthly&txn_type=recurring_payment_skipped&last_name=Doe&next_payment_date=00:00:00 Feb 01, 2013 PST&residence_country=AR&initial_payment_amount=0.00&rp_invoice_id=9944b730-50c6-0130-4651-22000a8eeeec&currency_code=EUR&time_created=00:00:00 Feb 01, 2013 PST&verify_sign=A99UBn.jdKHar60IJmHG2niLzQ4KAM2yA3Y6927Offn329AH3-eeOaKC&period_type= Regular&payer_status=unverified&tax=0.00&first_name=John&receiver_email=admin@allout.org&payer_id=1TLLMJP9PWL0E&product_type=1&shipping=0.00&amount_per_cycle=10.00&profile_status=Active&charset=windows-1252&notify_version=3.7&amount=10.00&outstanding_balance=0.00&recurring_payment_id=#{subscription_id}&product_name=Monthly donation of 10,00 € to AllOut.org&ipn_track_id=a097b45150e33"

          FakeWeb.register_uri :get, "http://testmovement:testmovement@example.com/api/movements/testmovement/donations?subscription_id=#{subscription_id}", :body => {:user => {:email => 'john.doe@example.com'}, :action_page => 'testplan'}.to_json

          params = {
              :donation_amount_in_cents => 1000,
              :member_email => 'john.doe@example',
              :subscription_id => '1234567',
              :transaction_id => '1d940c370adf22dce864544e0b85b79e',
              :action_page => 'testplan',
          }
          platform_post_url = "http://testmovement:testmovement@example.com/api/movements/testmovement/donations/handle_failed_payment"
          FakeWeb.register_uri :post, platform_post_url, :parameters => params, :status => [200, 'OK']

          ActiveMerchant::Billing::Integrations::Paypal::Notification.any_instance.should_receive(:acknowledge)

          post :create_from_paypal, { :classification => '501(c)3' }
          @request.env.delete('RAW_POST_DATA')

          response.code.should == '200'
        end

        it "should not acknowledge notification if reporting to platform fails" do
          subscription_id = "I-LL3IC9BB711M"
          @request.env['RAW_POST_DATA'] = "payment_cycle=Monthly&txn_type=recurring_payment_skipped&last_name=Doe&next_payment_date=00:00:00 Feb 01, 2013 PST&residence_country=AR&initial_payment_amount=0.00&rp_invoice_id=9944b730-50c6-0130-4651-22000a8eeeec&currency_code=EUR&time_created=00:00:00 Feb 01, 2013 PST&verify_sign=A99UBn.jdKHar60IJmHG2niLzQ4KAM2yA3Y6927Offn329AH3-eeOaKC&period_type= Regular&payer_status=unverified&tax=0.00&first_name=John&receiver_email=admin@allout.org&payer_id=1TLLMJP9PWL0E&product_type=1&shipping=0.00&amount_per_cycle=10.00&profile_status=Active&charset=windows-1252&notify_version=3.7&amount=10.00&outstanding_balance=0.00&recurring_payment_id=#{subscription_id}&product_name=Monthly donation of 10,00 € to AllOut.org&ipn_track_id=a097b45150e33"

          FakeWeb.register_uri :get, "http://testmovement:testmovement@example.com/api/movements/testmovement/donations.json?subscription_id=#{subscription_id}", :body => [{:user => {:email => 'john.doe@example.com'}, :action_page => 'testplan'}].to_json

          params = {
              :donation_amount_in_cents => 1000,
              :member_email => 'john.doe@example',
              :subscription_id => '1234567',
              :transaction_id => '1d940c370adf22dce864544e0b85b79e',
              :action_page => 'testplan',
          }
          platform_post_url = "http://testmovement:testmovement@example.com/api/movements/testmovement/donations/handle_failed_payment"
          FakeWeb.register_uri :post, platform_post_url, :parameters => params, :status => [500, 'Internal Server Error']

          ActiveMerchant::Billing::Integrations::Paypal::Notification.any_instance.should_not_receive(:acknowledge)

          post :create_from_paypal, { :classification => '501(c)3' }
          @request.env.delete('RAW_POST_DATA')

          response.code.should == '500'
        end
      end
    end
  end

end