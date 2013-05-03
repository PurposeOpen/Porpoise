# encoding: utf-8
require 'spec_helper'
require 'recurly'
require 'active_merchant'

describe ActionsController do

  before do
    stub_movement_request
    FakeWeb.register_uri :get, "http://testmovement:testmovement@example.com/api/movements/testmovement/action_pages/10.json", :body => { :title => "Save the Italian-speaking Turtles!", :content => "Save them!"}.to_json
    @take_action_url_stub = "http://testmovement:testmovement@example.com/api/movements/testmovement/action_pages/10/take_action.json?id=10&locale=pt&member_info%5Bemail%5D=bob%40example.com&member_info%5Bfirst_name%5D=Bob&member_info%5Blast_name%5D=Johnson&movement_id=testmovement"
  end

  it "should return an action content based on the specified action name and language" do
    get :show, { :id => 10, :locale => 'it'}

    Platform::ActionPage.headers['Accept-Language'].should eql 'it'
    assigns[:action_content].title.should eql "Save the Italian-speaking Turtles!"
    assigns[:action_content].content.should eql "Save them!"
    response.headers['Content-Language'].should eql 'it'
    response.should render_template "actions/show"
  end

  it "should request post-join content when searching for an action page if the user has signed" do
    FakeWeb.register_uri :get, "http://testmovement:testmovement@example.com/api/movements/testmovement/action_pages/10.json?member_has_joined=true",
                         :body => {:title => "Title", :content => "Content with email!"}.to_json
    get :show, {:id => 10, :locale => 'it', :email => 'john@banana-hammock.com'}

    Platform::ActionPage.headers['Accept-Language'].should eql 'it'
    assigns[:action_content].content.should eql "Content with email!"
  end

  it "should render page_not_available when the platform responds a 406 error" do
    FakeWeb.register_uri :get, "http://testmovement:testmovement@example.com/api/movements/testmovement/action_pages/notacceptable.json", :status => 406

    get :show, { :id => 'notacceptable', :locale => 'it' }

    response.should render_template :page_not_available
  end

  describe "#take_action" do
    before :each do
      stub_movement_request
      FakeWeb.register_uri :get, %r[http://testmovement:testmovement@example.com/api/movements/testmovement/action_pages/10.json], :body => { :id => 10, :title => "Save the Italian-speaking Turtles!", :content => "Save them!" }.to_json
      FakeWeb.register_uri :post, @take_action_url_stub, :body => { :next_page_identifier => nil, :member_id => 321 }.to_json, :status => 201
    end

    it "should post member details to the platform" do
      put :take_action, :id => 10, :member_info => {:first_name => "Bob", :last_name => "Johnson", :email => "bob@example.com"}, :locale => 'pt'
      FakeWeb.last_request.method.should eql "POST"
    end

    it "should redirect to the homepage if there is no next action" do
      put :take_action, :id => 10, :member_info => {:first_name => "Bob", :last_name => "Johnson", :email => "bob@example.com"}, :locale => 'pt'
      response.should redirect_to root_path
    end

    it "should redirect to the action page returned from the platform" do
      FakeWeb.register_uri :post, @take_action_url_stub,
                           :body => {
                               :member_id => 321,
                               :next_page_identifier => 123
                           }.to_json,
                           :status => 201
      put :take_action, { :id => 10, :member_info => {:first_name => "Bob", :last_name => "Johnson", :email => "bob@example.com"}, :locale => 'pt' }
      response.should redirect_to action_path('pt', 123)
    end

    describe 'setting member id in the session' do

      context 'member id is returned by the platform' do

        it "should set member id in the session" do
          FakeWeb.register_uri :post, @take_action_url_stub,
                               :body => {
                                   :next_page_identifier => 123,
                                   :member_id => 14
                               }.to_json,
                               :status => 201
          put :take_action, { :id => 10, :member_info => {:first_name => "Bob", :last_name => "Johnson", :email => "bob@example.com"}, :locale => 'pt' }

          session[:member_id].should == 14
        end

      end

      context 'member id is not returned by the platform' do

        it "should not set member id in the session" do
          FakeWeb.register_uri :post, @take_action_url_stub,
                               :body => {
                                   :next_page_identifier => 123,
                                   :member_id => ''
                               }.to_json
          put :take_action, { :id => 10, :member_info => {:first_name => "Bob", :last_name => "Johnson", :email => "bob@example.com"}, :locale => 'pt' }

          session[:member_id].should be_nil
        end

      end

    end

    it "should render the same page with a flash error if the action did not succeed" do
      FakeWeb.register_uri :post, @take_action_url_stub,
                           :body => {
                               :next_page_identifier => 123,
                               :error => "some_type_of_error"
                           }.to_json

      put :take_action, { :id => 10, :member_info => {:first_name => "Bob", :last_name => "Johnson", :email => "bob@example.com"}, :locale => 'pt' }

      flash[:error].should eql "some_type_of_error"
      response.should render_template(:show)
      assigns[:member].email.should eql "bob@example.com"
      assigns[:member].first_name.should eql "Bob"
      assigns[:member].last_name.should eql "Johnson"
      assigns[:action_content].title.should eql "Save the Italian-speaking Turtles!"
      assigns[:action_content].content.should eql "Save them!"
    end
  end

  describe "donations" do
    describe "paypal express donations" do
      before do
        FakeWeb.register_uri :post, "http://testmovement:testmovement@example.com/api/movements/testmovement/email_tracking/email_clicked", {}
        FakeWeb.register_uri :get, "http://testmovement:testmovement@example.com/api/movements/testmovement/action_pages/testplan.json", :body => {:id => 10, :title => "Save the Italian-speaking Turtles!", :content => "Save them!"}.to_json
        UUID.stub(:generate).and_return('generated-uuid')
        Platform.movement_name = 'testmovement'
      end
      
      describe "setting up paypal donations" do
        before do
          UUID.stub(:generate).and_return('generated-uuid')
        end

        context "one-time" do
          it "should redirect the user to Paypal with the donation currency and amount in cents using a 501(c)3 Paypal account" do
            successful_response = double
            successful_response.stub(:success?).and_return(true)
            successful_response.stub(:token).and_return('PaypalToken')
            ActiveMerchant::Billing::BogusGateway.any_instance.stub(:redirect_url_for).and_return('http://paypalurl.com')

            ActiveMerchant::Billing::BogusGateway.any_instance.should_receive(:setup_purchase).with(
              125, :ip => '0.0.0.0', :currency => 'BRL',
              :return_url => 'http://test.host/pt/actions/testplan/return_from_paypal?amount=125&classification=501%28c%293&currency=brl&is_recurring=false&t=email_tracking_info&order_id=generated-uuid',
              :cancel_return_url => 'http://test.host/pt/actions/testplan',
              :no_shipping => 1, :order_id => 'generated-uuid',
              :description => 'Doação de R$ 1,25 para testmovement:',
              :items => [{:amount => 125, :name => 'Doação de R$ 1,25 para testmovement:'}]
            ).and_return(successful_response)

            Payment::PaypalService.any_instance.should_receive(:get_paypal_gateway_for).with('501(c)3') { bogus_gateway }

            post :setup_paypal_donation, :id => 'testplan', :classification => '501(c)3', :t => 'email_tracking_info', :locale => 'pt',
                 :action_info => {
                    :currency => 'brl', 
                    :amount => '1.25', 
                    :is_recurring => 'false'}

            response.should redirect_to 'http://paypalurl.com'
          end

          it "should redirect the user to Paypal with the donation currency and amount in cents using a 501(c)4 Paypal account" do
            successful_response = double
            successful_response.stub(:success?).and_return(true)
            successful_response.stub(:token).and_return('PaypalToken')
            ActiveMerchant::Billing::BogusGateway.any_instance.stub(:redirect_url_for).and_return('http://paypalurl.com')

            ActiveMerchant::Billing::BogusGateway.any_instance.should_receive(:setup_purchase).with(
              125, :ip => '0.0.0.0', :currency => 'BRL',
              :return_url => 'http://test.host/pt/actions/testplan/return_from_paypal?amount=125&classification=501%28c%294&currency=brl&is_recurring=false&t=email_tracking_info&order_id=generated-uuid',
              :cancel_return_url => 'http://test.host/pt/actions/testplan',
              :no_shipping => 1, :order_id => 'generated-uuid',
              :description => 'Doação de R$ 1,25 para testmovement:',
              :items => [{:amount => 125, :name => 'Doação de R$ 1,25 para testmovement:'}]
            ).and_return(successful_response)

            Payment::PaypalService.any_instance.should_receive(:get_paypal_gateway_for).with('501(c)4') { bogus_gateway }

            post :setup_paypal_donation, :id => 'testplan', :classification => '501(c)4', :t => 'email_tracking_info', :locale => 'pt',
                 :action_info => {
                    :currency => 'brl', 
                    :amount => '1.25', 
                    :is_recurring => 'false'}

            response.should redirect_to 'http://paypalurl.com'
          end

          it "should show the action page with an error message when there is a problem communicating with Paypal" do
            failed_response = double
            failed_response.stub(:success?).and_return(false)
            ActiveMerchant::Billing::BogusGateway.any_instance.should_receive(:setup_purchase).and_return(failed_response)

            post :setup_paypal_donation, :id => 'testplan', :classification => '501(c)3', :t => 'email_tracking_info', :locale => 'pt',
                 :action_info => {
                    :currency => 'brl', 
                    :amount => '1.25', 
                    :is_recurring => 'false'}

            response.should render_template 'actions/show'
            response.headers['Content-Language'].should eql 'pt'
            flash[:error].should eql 'paypal_initialization_error'
          end
        end

        context "monthly" do
          it "should redirect the user to Paypal with the donation currency and amount in cents using a 501(c)3 Paypal account" do
            successful_response = double
            successful_response.stub(:success?).and_return(true)
            successful_response.stub(:token).and_return('PaypalToken')
            ActiveMerchant::Billing::BogusGateway.any_instance.stub(:redirect_url_for).and_return('http://paypalurl.com')

            ActiveMerchant::Billing::BogusGateway.any_instance.should_receive(:setup_purchase).with(
              125, :ip => '0.0.0.0', :currency => 'BRL',
              :return_url => 'http://test.host/pt/actions/testplan/return_from_paypal?amount=125&classification=501%28c%293&currency=brl&is_recurring=true&t=email_tracking_info&order_id=generated-uuid',
              :cancel_return_url => 'http://test.host/pt/actions/testplan',
              :no_shipping => 1, :order_id => 'generated-uuid',
              :description => 'Doação mensal de R$ 1,25 para testmovement.',
              :items => [{:amount => 125, :name => 'Doação mensal de R$ 1,25 para testmovement.'}],
              :billing_agreement => {:type => 'RecurringPayments', :description => 'Doação mensal de R$ 1,25 para testmovement.'}
            ).and_return(successful_response)

            Payment::PaypalService.any_instance.should_receive(:get_paypal_gateway_for).with('501(c)3') { ActiveMerchant::Billing::BogusGateway.new(:test => true) }

            post :setup_paypal_donation, :id => 'testplan', :classification => '501(c)3', :t => 'email_tracking_info', :locale => 'pt',
                 :action_info => {
                    :currency => 'brl', 
                    :amount => '1.25', 
                    :is_recurring => 'true'}
                

            response.should redirect_to 'http://paypalurl.com'
          end

          it "should redirect the user to Paypal with the donation currency and amount in cents using a 501(c)4 Paypal account" do
            successful_response = double
            successful_response.stub(:success?).and_return(true)
            successful_response.stub(:token).and_return('PaypalToken')
            ActiveMerchant::Billing::BogusGateway.any_instance.stub(:redirect_url_for).and_return('http://paypalurl.com')

            ActiveMerchant::Billing::BogusGateway.any_instance.should_receive(:setup_purchase).with(
              125, :ip => '0.0.0.0', :currency => 'BRL',
              :return_url => 'http://test.host/pt/actions/testplan/return_from_paypal?amount=125&classification=501%28c%294&currency=brl&is_recurring=true&t=email_tracking_info&order_id=generated-uuid',
              :cancel_return_url => 'http://test.host/pt/actions/testplan',
              :no_shipping => 1, :order_id => 'generated-uuid',
              :description => 'Doação mensal de R$ 1,25 para testmovement.',
              :items => [{:amount => 125, :name => 'Doação mensal de R$ 1,25 para testmovement.'}],
              :billing_agreement => {:type => 'RecurringPayments', :description => 'Doação mensal de R$ 1,25 para testmovement.'}
            ).and_return(successful_response)

            Payment::PaypalService.any_instance.should_receive(:get_paypal_gateway_for).with('501(c)4') { ActiveMerchant::Billing::BogusGateway.new(:test => true) }

            post :setup_paypal_donation, :id => 'testplan', :classification => '501(c)4', :t => 'email_tracking_info', :locale => 'pt',
                 :action_info => {
                    :currency => 'brl', 
                    :amount => '1.25', 
                    :is_recurring => 'true'}
                

            response.should redirect_to 'http://paypalurl.com'
          end

          it "should show the action page with an error message when there is a problem communicating with Paypal" do
            failed_response = double
            failed_response.stub(:success?).and_return(false)
            ActiveMerchant::Billing::BogusGateway.any_instance.should_receive(:setup_purchase).and_return(failed_response)

            post :setup_paypal_donation, :id => 'testplan', :classification => '501(c)3', :t => 'email_tracking_info', :locale => 'pt',
                 :action_info => {
                    :currency => 'brl', 
                    :amount => '1.25', 
                    :is_recurring => 'true'}

            response.should render_template 'actions/show'
            response.headers['Content-Language'].should eql 'pt'
            flash[:error].should eql 'paypal_initialization_error'
          end
        end
      end

      describe "return_from_paypal" do
        it "should set params from paypal in view" do
          get :return_from_paypal, :id => 'testplan', :classification => '501(c)3', :t => 'email_tracking_info', :locale => 'pt',
              :currency => 'brl',
              :amount => '1.25',
              :order_id => 'generated-uuid', 
              :token => 'PayPalToken', 
              :PayerID => 'Payer123',
              :is_recurring => 'true'

          assigns[:token].should eq('PayPalToken')
          assigns[:PayerID].should eq('Payer123')
          assigns[:currency].should eq('brl')
          assigns[:amount].should eq('1.25')
          assigns[:order_id].should eq('generated-uuid')
          assigns[:classification].should eq('501(c)3')
          assigns[:is_recurring].should eq('true')
          assigns[:t].should eq('email_tracking_info')
          assigns[:id].should eq('testplan')
        end
      end

      describe "completing paypal donations" do
        before do
          FakeWeb.register_uri :get, "http://testmovement:testmovement@example.com/api/movements/testmovement/action_pages/testplan.json?locale=pt", :body => {:id => 'testplan', :title => "Save the Italian-speaking Turtles!", :content => "Save them!"}.to_json
          FakeWeb.register_uri :post, "http://testmovement:testmovement@example.com/api/movements/testmovement/action_pages/10/donation_payment_error", :status => 200
        end

        it "should confirm the donation and post the data to the platform for one-time donations" do
          paypal_response = double
          paypal_response.stub(:[]).with(:transaction_id).and_return('PayPal Transaction ID')
          paypal_response.stub(:[]).with(:subscription_id).and_return('PayPal Subscription ID')
          Payment::PaypalService.any_instance.should_receive(:complete_paypal_donation)
            .with('PaypalToken', 'Payer123', 'brl', '125', '501(c)3', false)
            .and_return(paypal_response)

          FakeWeb.register_uri :post, "http://testmovement:testmovement@example.com/api/movements/testmovement/action_pages/testplan/take_action.json?action_info%5Bamount%5D=125&action_info%5Bconfirmed%5D=false&action_info%5Bcurrency%5D=brl&action_info%5Bfrequency%5D=one_off&action_info%5Border_id%5D=order123&action_info%5Bpayment_method%5D=paypal&action_info%5Btransaction_id%5D=PayPal+Transaction+ID&id=testplan&locale=pt&member_info%5Bcountry_iso%5D=Payer+Country&member_info%5Bemail%5D=Payer+Email&member_info%5Bfirst_name%5D=Payer+First+Name&member_info%5Blast_name%5D=Payer+Last+Name&member_info%5Bmobile_number%5D=Payer+Mobile+Number&member_info%5Bpostcode%5D=Payer+ZIP&member_info%5Bstreet_address%5D=Payer+Address&movement_id=testmovement&t=email_tracking_info", 
                               :body => { :member_id => 123, :next_page_identifier => 404 }.to_json,
                               :status => 201

          post :complete_paypal_donation, :id => 'testplan', :classification => '501(c)3', :is_recurring => 'false', :t => 'email_tracking_info', :locale => 'pt',
              :token => 'PaypalToken', :PayerID => 'Payer123', :currency => 'brl', :amount => '125', :order_id => 'order123',
              :member_info => {
                :email => 'Payer Email',
                :first_name => 'Payer First Name',
                :last_name => 'Payer Last Name',
                :country_iso => 'Payer Country',
                :postcode => 'Payer ZIP',
                :mobile_number => 'Payer Mobile Number',
                :street_address => 'Payer Address'
              }

          response.should redirect_to action_path('pt', 404)
          FakeWeb.last_request.path.should match /\/api\/movements\/testmovement\/action_pages\/testplan\/take_action\.json/
        end

        it "should confirm the donation and post the data to the platform for recurring donations" do
          paypal_response = double
          paypal_response.stub(:[]).with(:transaction_id).and_return('PayPal Transaction ID')
          paypal_response.stub(:[]).with(:subscription_id).and_return('PayPal Subscription ID')
          Payment::PaypalService.any_instance.should_receive(:complete_paypal_donation)
            .with('PaypalToken', 'Payer123', 'brl', '125', '501(c)3', true)
            .and_return(paypal_response)

          FakeWeb.register_uri :post, "http://testmovement:testmovement@example.com/api/movements/testmovement/action_pages/testplan/take_action.json?action_info%5Bconfirmed%5D=false&action_info%5Bcurrency%5D=brl&action_info%5Bfrequency%5D=monthly&action_info%5Bpayment_method%5D=paypal&action_info%5Bsubscription_amount%5D=125&action_info%5Bsubscription_id%5D=PayPal+Subscription+ID&id=testplan&locale=pt&member_info%5Bcountry_iso%5D=Payer+Country&member_info%5Bemail%5D=Payer+Email&member_info%5Bfirst_name%5D=Payer+First+Name&member_info%5Blast_name%5D=Payer+Last+Name&member_info%5Bmobile_number%5D=Payer+Mobile+Number&member_info%5Bpostcode%5D=Payer+ZIP&member_info%5Bstreet_address%5D=Payer+Address&movement_id=testmovement&t=email_tracking_info", 
                               :body => { :member_id => 123, :next_page_identifier => 404 }.to_json,
                               :status => 201

          post :complete_paypal_donation, :id => 'testplan', :classification => '501(c)3', :is_recurring => 'true', :t => 'email_tracking_info', :locale => 'pt',
              :token => 'PaypalToken', :PayerID => 'Payer123', :currency => 'brl', :amount => '125', :order_id => 'order123',
              :member_info => {
                :email => 'Payer Email',
                :first_name => 'Payer First Name',
                :last_name => 'Payer Last Name',
                :country_iso => 'Payer Country',
                :postcode => 'Payer ZIP',
                :mobile_number => 'Payer Mobile Number',
                :street_address => 'Payer Address'
              }

          response.should redirect_to action_path('pt', 404)
          FakeWeb.last_request.path.should match /\/api\/movements\/testmovement\/action_pages\/testplan\/take_action\.json/
        end

        it "should notify Platform when there is a problem confirming the donation with PayPal Express" do
          failed_complete_donation_response = double
          failed_complete_donation_response.stub(:success?).and_return(false)
          failed_complete_donation_response.stub(:message).and_return('Failure message')
          failed_complete_donation_response.stub(:avs_result).and_return({ :code => 'P', :message => 'AVS Result', :street_match => 'X', :postal_match => 'X' })
          failed_complete_donation_response.stub(:cvv_result).and_return({ :code => 'E', :message => 'CVV Result' })
          failed_complete_donation_response.stub(:params).and_return({'error_codes' => 111111})
          transaction_details_response = { :payer_first_name => 'Payer First Name', :payer_last_name => 'Payer Last Name', :payer_email => 'Payer Email', :payer_country => 'Payer Country', :payer_zip => 'Payer ZIP', :success => true }

          Payment::PaypalService.any_instance.should_receive(:complete_paypal_donation).with("PaypalToken", "Payer123", "USD", "125", "501(c)3", false).and_raise(Payment::PaymentError.new(failed_complete_donation_response))
          Payment::PaypalService.any_instance.should_receive(:retrieve_transaction_details).with('PaypalToken', '501(c)3').and_return(transaction_details_response)

          ActionsController.any_instance.stub(:post_to_platform)
            .with("http://example.com/api/movements/testmovement/action_pages/10/donation_payment_error", {
                'member_info[email]' => 'Payer Email',
                'member_info[first_name]' => 'Payer First Name',
                'member_info[last_name]' => 'Payer Last Name',
                'member_info[country_iso]' => 'Payer Country',
                'member_info[postcode]' => 'Payer ZIP',
                'payment_error_data[error_code]' => 111111,
                'payment_error_data[message]' => "Failure message\nAVS:\n---\n:code: P\n:message: AVS Result\n:street_match: X\n:postal_match: X\n\nCVV:\n---\n:code: E\n:message: CVV Result\n",
                'payment_error_data[donation_payment_method]' => :paypal,
                'payment_error_data[donation_amount_in_cents]' => '125',
                'payment_error_data[donation_currency]' => 'USD'
            })

          post :complete_paypal_donation, :id => 10, :token => 'PaypalToken', :PayerID => 'Payer123', :currency => 'USD',
              :amount => '125', :country_iso => 'br', :postcode => '12345', :classification => '501(c)3', :locale => 'de'
        end

        it "should notify Platform when there is a problem confirming the donation with PayPal Express even if payer data cannot be retrieved" do
          failed_complete_donation_response = double
          failed_complete_donation_response.stub(:success?).and_return(false)
          failed_complete_donation_response.stub(:message).and_return('Failure message')
          failed_complete_donation_response.stub(:avs_result).and_return({ :code => 'P', :message => 'AVS Result', :street_match => 'X', :postal_match => 'X' })
          failed_complete_donation_response.stub(:cvv_result).and_return({ :code => 'E', :message => 'CVV Result' })
          failed_complete_donation_response.stub(:params).and_return({'error_codes' => 111111})
          transaction_details_response = double
          transaction_details_response.stub(:success?).and_return(false)

          Payment::PaypalService.any_instance.should_receive(:complete_paypal_donation)
            .with("PaypalToken", "Payer123", "USD", "125", "501(c)3", false)
            .and_raise(Payment::PaymentError.new(failed_complete_donation_response))
          Payment::PaypalService.any_instance.should_receive(:retrieve_transaction_details).with('PaypalToken', '501(c)3').and_return(transaction_details_response)

          ActionsController.any_instance.stub(:post_to_platform)
            .with("http://example.com/api/movements/testmovement/action_pages/10/donation_payment_error", {
                'payment_error_data[error_code]' => 111111,
                'payment_error_data[message]' => "Failure message\nAVS:\n---\n:code: P\n:message: AVS Result\n:street_match: X\n:postal_match: X\n\nCVV:\n---\n:code: E\n:message: CVV Result\n",
                'payment_error_data[donation_payment_method]' => :paypal,
                'payment_error_data[donation_amount_in_cents]' => '125',
                'payment_error_data[donation_currency]' => 'USD'
            })

          post :complete_paypal_donation, :id => 10, :token => 'PaypalToken', :PayerID => 'Payer123', :currency => 'USD',
              :amount => '125', :country_iso => 'br', :postcode => '12345', :classification => '501(c)3', :locale => 'de'
        end

        it "should show the action page with an error message when there is a problem confirming the donation with Paypal" do
          failed_response = double
          failed_response.stub(:success?).and_return(false)
          failed_response.stub(:message).and_return('Message')
          failed_response.stub(:avs_result).and_return({ :code => 'P', :message => 'AVS Result', :street_match => 'X', :postal_match => 'X' })
          failed_response.stub(:cvv_result).and_return({ :code => 'E', :message => 'CVV Result' })
          failed_response.stub(:params).and_return({'error_codes' => 111111})
          ActiveMerchant::Billing::BogusGateway.any_instance.should_receive(:purchase).with(125, :currency => 'USD',
              :payer_id => 'Payer123', :token => 'PaypalToken').and_return(failed_response)

          post :complete_paypal_donation, :id => 10, :token => 'PaypalToken', :PayerID => 'Payer123', :currency => 'USD',
              :amount => '125', :country_iso => 'br', :postcode => '12345', :classification => '501(c)3', :locale => 'de'

          response.should render_template 'actions/show'
          response.headers['Content-Language'].should eql 'de'
          flash[:error].should eql 'donation_information_error'
        end
      end
    end

    describe "credit card donations" do
      describe "donate_with_credit_card_one_time_trx" do
        before do
          FakeWeb.register_uri :get, "http://testmovement:testmovement@example.com/api/movements/testmovement/action_pages/10.json?locale=en", :body => {:id => 10, :title => "Save the Italian-speaking Turtles!", :content => "Save them!"}.to_json
        end

        it "should call Recurly API using C3 account and notify Platform if transaction is successful for tax deductible donation" do
          ENV['501C3_RECURLY_KEY'] = 'Recurly key for C3 associated PayPal account (one-off donation test)'

          params = {:amount_in_cents => 12500,
                    :currency => 'USD',
                    :account => {
                        :account_code => 'john.doe@example.com',
                        :billing_info => {
                            :first_name => 'John',
                            :last_name => 'Doe',
                            :number => '4111111111111111',
                            :verification_value => '123',
                            :month => 12,
                            :year => 2020
                        }
                    }
          }

          transaction = OpenStruct.new
          transaction.response = OpenStruct.new
          transaction.response.code = '201'
          transaction.uuid = "10"
          transaction.invoice = OpenStruct.new
          transaction.invoice.invoice_number = 123

          Recurly.should_receive(:api_key=).with('Recurly key for C3 associated PayPal account (one-off donation test)')
          Recurly::Transaction.should_receive(:create).with(params).and_return(transaction)

          platform_post_url = 'http://testmovement:testmovement@example.com/api/movements/testmovement/action_pages/10/take_action.json?action_info%5Bamount%5D=12500&action_info%5Bconfirmed%5D=false&action_info%5Bcurrency%5D=USD&action_info%5Bfrequency%5D=one_off&action_info%5Border_id%5D=123&action_info%5Bpayment_method%5D=credit_card&action_info%5Btransaction_id%5D=10&id=10&locale=en&member_info%5Bcountry_iso%5D=us&member_info%5Bemail%5D=john.doe%40example.com&member_info%5Bfirst_name%5D=John&member_info%5Blast_name%5D=Doe&member_info%5Bpostcode%5D=123123&movement_id=testmovement'
          FakeWeb.register_uri :post, platform_post_url, :body => { :next_page_identifier => 404 }.to_json, :status => 201


          post :donate_with_credit_card, :id => 10, :locale => 'en',
               :classification => '501(c)3',
               :member_info => {
                   :email => 'john.doe@example.com', :first_name => 'John', :last_name => 'Doe',
                   :country_iso => 'us', :postcode => '123123'},
               :action_info => {
                   :currency => 'USD', :amount => '125', :name_on_card => "John Doe", :card_type => "visa",
                   :card_number => '4111111111111111', :card_expiration_month => 12,
                   :card_expiration_year => 2020, :card_cvv2 => '123',
                   :is_recurring => 'false'}
        end

        it "should call Recurly API using C4 account and notify Platform if transaction is successful for non tax deductible donation" do
          ENV['501C4_RECURLY_KEY'] = 'Recurly key for C4 associated PayPal account (one-off donation test)'

          params = {:amount_in_cents => 12500,
                    :currency => 'USD',
                    :account => {
                        :account_code => 'john.doe@example.com',
                        :billing_info => {
                            :first_name => 'John',
                            :last_name => 'Doe',
                            :number => '4111111111111111',
                            :verification_value => '123',
                            :month => 12,
                            :year => 2020
                        }
                    }
          }

          transaction = OpenStruct.new
          transaction.response = OpenStruct.new
          transaction.response.code = '201'
          transaction.uuid = "10"
          transaction.invoice = OpenStruct.new
          transaction.invoice.invoice_number = 123

          Recurly.should_receive(:api_key=).with('Recurly key for C4 associated PayPal account (one-off donation test)')
          Recurly::Transaction.should_receive(:create).with(params).and_return(transaction)

          platform_post_url = 'http://testmovement:testmovement@example.com/api/movements/testmovement/action_pages/10/take_action.json?action_info%5Bamount%5D=12500&action_info%5Bconfirmed%5D=false&action_info%5Bcurrency%5D=USD&action_info%5Bfrequency%5D=one_off&action_info%5Border_id%5D=123&action_info%5Bpayment_method%5D=credit_card&action_info%5Btransaction_id%5D=10&id=10&locale=en&member_info%5Bcountry_iso%5D=us&member_info%5Bemail%5D=john.doe%40example.com&member_info%5Bfirst_name%5D=John&member_info%5Blast_name%5D=Doe&member_info%5Bpostcode%5D=123123&movement_id=testmovement'
          FakeWeb.register_uri :post, platform_post_url, :body => { :next_page_identifier => 404}.to_json, :status => 201


          post :donate_with_credit_card, :id => 10, :locale => 'en',
               :classification => '501(c)4',
               :member_info => {
                   :email => 'john.doe@example.com', :first_name => 'John', :last_name => 'Doe',
                   :country_iso => 'us', :postcode => '123123'},
               :action_info => {
                   :currency => 'USD', :amount => '125', :name_on_card => "John Doe", :card_type => "visa",
                   :card_number => '4111111111111111', :card_expiration_month => 12,
                   :card_expiration_year => 2020, :card_cvv2 => '123',
                   :is_recurring => 'false'}
        end

        it "should notify Platform when there is a problem processing the donation with Recurly" do
          response = {
              :error_code => 'error_code',
              :error_message => 'error_message'
          }

          Recurly::Transaction.should_receive(:create).and_raise(Payment::PaymentError.new(response))

          ActionsController.any_instance.should_receive(:post_to_platform).with("http://example.com/api/movements/testmovement/action_pages/10/donation_payment_error", {"member_info[email]" => "john.doe@example.com", "member_info[first_name]" => "John", "member_info[last_name]" => "Doe", "member_info[country_iso]" => "us", "member_info[postcode]" => "123123", "payment_error_data[error_code]" => "error_code", "payment_error_data[message]" => "error_message", "payment_error_data[donation_payment_method]" => :recurly, "payment_error_data[donation_amount_in_cents]" => 12500, "payment_error_data[donation_currency]" => "USD"})

          post :donate_with_credit_card, :id => 10, :locale => 'en',
               :member_info => {
                   :email => 'john.doe@example.com', :first_name => 'John', :last_name => 'Doe',
                   :country_iso => 'us', :postcode => '123123'},
               :action_info => {
                   :currency => 'USD', :amount => '125', :name_on_card => "John Doe", :card_type => "visa",
                   :card_number => '4111111111111111', :card_expiration_month => 12,
                   :card_expiration_year => 2020, :card_cvv2 => '123',
                   :is_recurring => 'false'}
        end

        it "should redirect the user to the action page with an error message when the credit card is not accepted" do
          response = {
              :error_code => 'error_code',
              :error_message => 'error_message'}

          Recurly::Transaction.should_receive(:create).and_raise(Payment::PaymentError.new(response))

          ActionsController.any_instance.should_receive(:post_to_platform).with("http://example.com/api/movements/testmovement/action_pages/10/donation_payment_error", {"member_info[email]" => "john.doe@example.com", "member_info[first_name]" => "John", "member_info[last_name]" => "Doe", "member_info[country_iso]" => "us", "member_info[postcode]" => "123123", "payment_error_data[error_code]" => "error_code", "payment_error_data[message]" => "error_message", "payment_error_data[donation_payment_method]" => :recurly, "payment_error_data[donation_amount_in_cents]" => 12500, "payment_error_data[donation_currency]" => "USD"})

          post :donate_with_credit_card, :id => 10, :locale => 'en',
               :member_info => {
                   :email => 'john.doe@example.com', :first_name => 'John', :last_name => 'Doe',
                   :country_iso => 'us', :postcode => '123123'},
               :action_info => {
                   :currency => 'USD', :amount => '125', :name_on_card => "John Doe", :card_type => "visa",
                   :card_number => '4111111111111111', :card_expiration_month => 12,
                   :card_expiration_year => 2020, :card_cvv2 => '123',
                   :is_recurring => 'false'}

          response.should redirect_to action_path('en', 10)
          flash[:error].should eql 'credit_card_donation_error'
        end
      end

      describe "donate_with_credit_card_recurrent_trx" do
        before do
          FakeWeb.register_uri :get, "http://testmovement:testmovement@example.com/api/movements/testmovement/action_pages/testplan.json?locale=en", :body => {:id => 'testplan', :title => "Save the Italian-speaking Turtles!", :content => "Save them!"}.to_json
        end

        it "should call Recurly API using C3 account and notify Platform if transaction is successful for tax deductible donation" do
          ENV['501C3_RECURLY_KEY'] = 'Recurly key for C3 associated PayPal account (monthly donation test)'

          params = {:plan_code => 'testplan--monthly',
                    :currency => 'USD',
                    :unit_amount_in_cents => 100,
                    :quantity => 125,
                    :account => {
                        :account_code => 'john.doe@example.com',
                        :email => 'john.doe@example.com',
                        :first_name => 'John',
                        :last_name => 'Doe',
                        :billing_info => {
                            :first_name => 'John',
                            :last_name => 'Doe',
                            :number => '4111111111111111',
                            :verification_value => '123',
                            :month => 12,
                            :year => 2020
                        }
                    }
          }

          transaction = OpenStruct.new
          transaction.response = OpenStruct.new
          transaction.response.code = '201'
          transaction.uuid = "10"

          Recurly.should_receive(:api_key=).with('Recurly key for C3 associated PayPal account (monthly donation test)')
          Recurly::Plan.should_receive(:find).with('testplan--monthly').and_return(true)
          Recurly::Subscription.should_receive(:create).with(params).and_return(transaction)

          platform_post_url = 'http://testmovement:testmovement@example.com/api/movements/testmovement/action_pages/testplan/take_action.json?action_info%5Bconfirmed%5D=false&action_info%5Bcurrency%5D=USD&action_info%5Bfrequency%5D=monthly&action_info%5Bpayment_method%5D=credit_card&action_info%5Bsubscription_amount%5D=12500&action_info%5Bsubscription_id%5D=10&action_info%5Btransaction_id%5D=10&id=testplan&locale=en&member_info%5Bcountry_iso%5D=us&member_info%5Bemail%5D=john.doe%40example.com&member_info%5Bfirst_name%5D=John&member_info%5Blast_name%5D=Doe&member_info%5Bpostcode%5D=123123&movement_id=testmovement'
          FakeWeb.register_uri :post, platform_post_url, :body => { :next_page_identifier => 404}.to_json, :status => 201

          post :donate_with_credit_card, :id => 'testplan', :action_internal_id => 'testplan', :locale => 'en',
               :classification => '501(c)3',
               :member_info => {
                   :email => 'john.doe@example.com', :first_name => 'John', :last_name => 'Doe',
                   :country_iso => 'us', :postcode => '123123'},
               :action_info => {
                   :currency => 'USD', :amount => '125', :name_on_card => "John Doe", :card_type => "visa",
                   :card_number => '4111111111111111', :card_expiration_month => 12,
                   :card_expiration_year => 2020, :card_cvv2 => '123',
                   :order_id => '12345',
                   :is_recurring => 'true'}
        end

        it "should call Recurly API using C4 account and notify Platform if transaction is successful for tax deductible donation" do
          ENV['501C4_RECURLY_KEY'] = 'Recurly key for C4 associated PayPal account (monthly donation test)'

          params = {:plan_code => 'testplan--monthly',
                    :currency => 'USD',
                    :unit_amount_in_cents => 100,
                    :quantity => 125,
                    :account => {
                        :account_code => 'john.doe@example.com',
                        :email => 'john.doe@example.com',
                        :first_name => 'John',
                        :last_name => 'Doe',
                        :billing_info => {
                            :first_name => 'John',
                            :last_name => 'Doe',
                            :number => '4111111111111111',
                            :verification_value => '123',
                            :month => 12,
                            :year => 2020
                        }
                    }
          }

          transaction = OpenStruct.new
          transaction.response = OpenStruct.new
          transaction.response.code = '201'
          transaction.uuid = "10"

          Recurly.should_receive(:api_key=).with('Recurly key for C4 associated PayPal account (monthly donation test)')
          Recurly::Plan.should_receive(:find).with('testplan--monthly').and_return(true)
          Recurly::Subscription.should_receive(:create).with(params).and_return(transaction)

          platform_post_url = 'http://testmovement:testmovement@example.com/api/movements/testmovement/action_pages/testplan/take_action.json?action_info%5Bconfirmed%5D=false&action_info%5Bcurrency%5D=USD&action_info%5Bfrequency%5D=monthly&action_info%5Border_id%5D=12345&action_info%5Bpayment_method%5D=credit_card&action_info%5Bsubscription_amount%5D=12500&action_info%5Bsubscription_id%5D=10&action_info%5Btransaction_id%5D=10&id=testplan&locale=en&member_info%5Bcountry_iso%5D=us&member_info%5Bemail%5D=john.doe%40example.com&member_info%5Bfirst_name%5D=John&member_info%5Blast_name%5D=Doe&member_info%5Bpostcode%5D=123123&movement_id=testmovement'
          FakeWeb.register_uri :post, platform_post_url, :body => { :next_page_identifier => 404}.to_json, :status => 201


          post :donate_with_credit_card, :id => 'testplan', :action_internal_id => 'testplan', :locale => 'en',
               :classification => '501(c)4',
               :member_info => {
                   :email => 'john.doe@example.com', :first_name => 'John', :last_name => 'Doe',
                   :country_iso => 'us', :postcode => '123123'},
               :action_info => {
                   :currency => 'USD', :amount => '125', :name_on_card => "John Doe", :card_type => "visa",
                   :card_number => '4111111111111111', :card_expiration_month => 12,
                   :card_expiration_year => 2020, :card_cvv2 => '123', :order_id => '12345',
                   :is_recurring => 'true'}
        end

        it "should call Recurly API, create plan if not exists and notify Platform if transaction is successful" do
          ENV['501C4_RECURLY_KEY'] = 'Recurly key for C4 associated PayPal account (plan creation donation test)'

          params = {:plan_code => 'testplan--monthly',
                    :currency => 'USD',
                    :unit_amount_in_cents => 100,
                    :quantity => 125,
                    :account => {
                        :account_code => 'john.doe@example.com',
                        :email => 'john.doe@example.com',
                        :first_name => 'John',
                        :last_name => 'Doe',
                        :billing_info => {
                            :first_name => 'John',
                            :last_name => 'Doe',
                            :number => '4111111111111111',
                            :verification_value => '123',
                            :month => 12,
                            :year => 2020
                        }
                    }
          }


          transaction = OpenStruct.new
          transaction.response = OpenStruct.new
          transaction.response.code = '201'
          transaction.uuid = "10"
          transaction.invoice = OpenStruct.new

          Recurly.should_receive(:api_key=).with('Recurly key for C4 associated PayPal account (plan creation donation test)')
          Recurly::Plan.should_receive(:find).with('testplan--monthly').and_raise(Payment::PaymentError.new({}))

          plan_params = {:plan_code => 'testplan--monthly',
                         :name => "testplan--monthly",
                         :unit_amount_in_cents => {'USD' => 100, 'EUR' => 100},
                         :setup_fee_in_cents => {'USD' => 0, 'EUR' => 0},
                         :plan_interval_length => 1,
                         :plan_interval_unit => 'months'}

          Recurly::Plan.should_receive(:create).with(plan_params).and_return(true)

          Recurly::Subscription.should_receive(:create).with(params).and_return(transaction)

          platform_post_url = 'http://testmovement:testmovement@example.com/api/movements/testmovement/action_pages/testplan/take_action.json?action_info%5Bconfirmed%5D=false&action_info%5Bcurrency%5D=USD&action_info%5Bfrequency%5D=monthly&action_info%5Border_id%5D=12345&action_info%5Bpayment_method%5D=credit_card&action_info%5Bsubscription_amount%5D=12500&action_info%5Bsubscription_id%5D=10&id=testplan&locale=en&member_info%5Bcountry_iso%5D=us&member_info%5Bemail%5D=john.doe%40example.com&member_info%5Bfirst_name%5D=John&member_info%5Blast_name%5D=Doe&member_info%5Bpostcode%5D=123123&movement_id=testmovement'
          FakeWeb.register_uri :post, platform_post_url, :body => {:next_page_identifier => 404}.to_json, :status => 201

          post :donate_with_credit_card, :id => 'testplan', :action_internal_id => 'testplan', :locale => 'en',
               :classification => '501(c)4',
               :member_info => {
                   :email => 'john.doe@example.com', :first_name => 'John', :last_name => 'Doe',
                   :country_iso => 'us', :postcode => '123123'},
               :action_info => {
                   :currency => 'USD', :amount => '125', :name_on_card => "John Doe", :card_type => "visa",
                   :card_number => '4111111111111111', :card_expiration_month => 12,
                   :card_expiration_year => 2020, :card_cvv2 => '123', :order_id => '12345',
                   :is_recurring => 'true'}
        end

        it "should notify Platform when there is a problem processing the donation with Recurly" do
          response = {
              :error_code => 'error_code',
              :error_message => 'error_message'}

          Recurly::Plan.should_receive(:find).with('testplan--monthly').and_return(true)
          Recurly::Subscription.should_receive(:create).and_raise(Payment::PaymentError.new(response))

          ActionsController.any_instance.should_receive(:post_to_platform).with("http://example.com/api/movements/testmovement/action_pages/testplan/donation_payment_error", {"member_info[email]" => "john.doe@example.com", "member_info[first_name]" => "John", "member_info[last_name]" => "Doe", "member_info[country_iso]" => "us", "member_info[postcode]" => "123123", "payment_error_data[error_code]" => "error_code", "payment_error_data[message]" => "error_message", "payment_error_data[donation_payment_method]" => :recurly, "payment_error_data[donation_amount_in_cents]" => 12500, "payment_error_data[donation_currency]" => "USD"})

          post :donate_with_credit_card, :id => 'testplan', :action_internal_id => 'testplan', :locale => 'en',
               :member_info => {
                   :email => 'john.doe@example.com', :first_name => 'John', :last_name => 'Doe',
                   :country_iso => 'us', :postcode => '123123'},
               :action_info => {
                   :currency => 'USD', :amount => '125', :name_on_card => "John Doe", :card_type => "visa",
                   :card_number => '4111111111111111', :card_expiration_month => 12,
                   :card_expiration_year => 2020, :card_cvv2 => '123',
                   :is_recurring => 'true'}
        end

        it "should redirect the user to the action page with an error message when the credit card is not accepted" do
          response = {
              :error_code => 'error_code',
              :error_message => 'error_message'}

          Recurly::Plan.should_receive(:find).with('testplan--monthly').and_return(true)
          Recurly::Subscription.should_receive(:create).and_raise(Payment::PaymentError.new(response))

          ActionsController.any_instance.should_receive(:post_to_platform).with("http://example.com/api/movements/testmovement/action_pages/testplan/donation_payment_error", {"member_info[email]" => "john.doe@example.com", "member_info[first_name]" => "John", "member_info[last_name]" => "Doe", "member_info[country_iso]" => "us", "member_info[postcode]" => "123123", "payment_error_data[error_code]" => "error_code", "payment_error_data[message]" => "error_message", "payment_error_data[donation_payment_method]" => :recurly, "payment_error_data[donation_amount_in_cents]" => 12500, "payment_error_data[donation_currency]" => "USD"})

          post :donate_with_credit_card, :id => 'testplan', :action_internal_id => 'testplan', :locale => 'en',
               :member_info => {
                   :email => 'john.doe@example.com', :first_name => 'John', :last_name => 'Doe',
                   :country_iso => 'us', :postcode => '123123'},
               :action_info => {
                   :currency => 'USD', :amount => '125', :name_on_card => "John Doe", :card_type => "visa",
                   :card_number => '4111111111111111', :card_expiration_month => 12,
                   :card_expiration_year => 2020, :card_cvv2 => '123',
                   :is_recurring => 'true'}

          response.should redirect_to action_path('en', 'testplan')
          flash[:error].should eql 'credit_card_donation_error'
        end

        it "should redirect the user to the action page with an error message when there is duplication subscription situation" do
          subscription = OpenStruct.new
          subscription.response = OpenStruct.new
          subscription.response.code = '422'
          subscription.response.body = '<?xml version="1.0" encoding="UTF-8"?> <errors>   <error field="subscription.base" symbol="already_subscribed">You already have a subscription to this plan.</error> </errors>'

          Recurly::Plan.should_receive(:find).with('testplan--monthly').and_return(true)
          Recurly::Subscription.should_receive(:create).and_return(subscription)

          post :donate_with_credit_card, :id => 'testplan', :action_internal_id => 'testplan', :locale => 'en',
               :member_info => {
                   :email => 'john.doe@example.com', :first_name => 'John', :last_name => 'Doe',
                   :country_iso => 'us', :postcode => '123123'},
               :action_info => {
                   :currency => 'USD', :amount => '125', :name_on_card => "John Doe", :card_type => "visa",
                   :card_number => '4111111111111111', :card_expiration_month => 12,
                   :card_expiration_year => 2020, :card_cvv2 => '123',
                   :is_recurring => 'true'}

          response.should redirect_to action_path('en', 'testplan')
          flash[:error].should eql 'duplicated_subscription_error'
        end
      end
    end
  end

  describe "member_info" do
    it "should return member's first and last names by email" do
      FakeWeb.register_uri :get, 'http://testmovement:testmovement@example.com/api/movements/testmovement/members.json?email=john.doe@example.com', :body => { :first_name => 'John', :last_name => 'Doe', :email => 'john.doe@example.com', :country_iso => 'us'}.to_json

      get :member_info, :locale => 'pt', :action_id => 10, :email => 'john.doe@example.com', :callback => 'this_is_the_callback'

      response.status.should == 200

      response.body.should match /this_is_the_callback\(.+\)/
      json = JSON.parse(response.body.match(/this_is_the_callback\((.+)\)/)[1])

      json.length.should == 2
      json['first_name'].should == 'John'
      json['last_name'].should == 'Doe'
    end
  end

  describe "GET preview" do
    it "should return preview for action page which are unpublished" do
      FakeWeb.register_uri :get, "http://testmovement:testmovement@example.com/api/movements/testmovement/action_pages/10/preview.json",
                           :body => {:title => "Title", :content => "Content with email!"}.to_json
      get :preview, {:id => 10, :locale => 'it'}

      Platform::ActionPage.headers['Accept-Language'].should eql 'it'
      assigns[:action_content].content.should eql "Content with email!"
      assigns[:action_content].title.should eql "Title"
      assigns[:member].should be_kind_of(Platform::Member)
    end
  end

  def bogus_gateway
    ActiveMerchant::Billing::BogusGateway.new(:test => true)
  end
end

