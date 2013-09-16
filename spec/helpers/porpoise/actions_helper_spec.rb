require 'spec_helper'
require 'ostruct'

describe Porpoise::ActionsHelper do
  it "should map partial names to content module types" do
    hash = {
      "PetitionModule" => 'petition',
      "JoinModule" => 'join',
      "TellAFriendModule" => 'taf',
      "HtmlModule" => 'generic',
      "AccordionModule" => 'generic',
      "UnsubscribeModule" => 'unsubscribe',
      "DonationModule" => 'donation',
      "EmailTargetsModule" => 'email_targets'
    }
    hash.each_key do |module_name|
      partial_for(mock_module(module_name)).should == hash[module_name]
    end
  end

  describe 'active flag' do
    it "should show disabled content if content module is not active" do
      partial_for(mock_module('PetitionModule', options: {active: 'false'})).should == 'disabled'
    end

    it "should show content module if active" do
      partial_for(mock_module('PetitionModule', options: {active: 'true'})).should == 'petition'
    end
  end

  it "should look for a PetitionModule given a collection of modules" do
    petition_module = OpenStruct.new(:type => 'PetitionModule')
    tafModule = OpenStruct.new(:type => 'TellAFriendModule')

    with_petition_module([tafModule, petition_module]) do |mod|
      mod.should equal petition_module
    end
  end

  describe "get_counter_module" do
    shared_examples_for "counter for ask module" do |module_type|
      it "should return #{module_type} if present" do
        counter_module = mock_module(module_type)
        get_counter_module([counter_module]).should == counter_module
      end
    end

    it_should_behave_like "counter for ask module", "PetitionModule"
    it_should_behave_like "counter for ask module", "DonationModule"
    it_should_behave_like "counter for ask module", "EmailTargetsModule"

    it "should be nil if no ask module is present" do
      counter_module = mock_module('JoinModule')
      get_counter_module([counter_module]).should be_nil
    end

    it "should return action counter module if TellAFriendModule includes action counter" do
      petition_module = mock_module('PetitionModule')
      petition_page = mock('page', sidebar_content_modules: [petition_module])
      taf_module = mock_module('TellAFriendModule', options: {include_action_counter: 'true', action_counter_page_id: 5})
      Platform::ActionPage.should_receive(:find_preview).with(5).and_return(petition_page)

      get_counter_module([taf_module]).should == petition_module
    end

    it "should be nil if TellAFriendModule does not include action counter" do
      counter_module = mock_module('TellAFriendModule', options: {include_action_counter: 'false'})
      get_counter_module([counter_module]).should be_nil
    end
  end

  describe "display_counter_for?" do
    context "petition module" do
      it "should be true if signatures exceeds threshold" do
        content_module = mock_module('PetitionModule', signatures: 150, options: {thermometer_threshold: 100})
        display_counter_for?(content_module).should be_true
      end

      it "should be false if signatures does not exceed threshold" do
        content_module = mock_module('PetitionModule', signatures: 50, options: {thermometer_threshold: 100})
        display_counter_for?(content_module).should be_false
      end

      it "should be false if goal and threshold are set to 0" do
        content_module = mock_module('PetitionModule', signatures: 10, options: {thermometer_threshold: 0, signatures_goal: 0})
        display_counter_for?(content_module).should be_false
      end
    end

    context "email targets module" do
      it "should be true if emails sent exceeds threshold" do
        content_module = mock_module('EmailTargetsModule', emails_sent: 150, options: {thermometer_threshold: 100})
        display_counter_for?(content_module).should be_true
      end

      it "should be false if emails sent does not exceed threshold" do
        content_module = mock_module('EmailTargetsModule', emails_sent: 50, options: {thermometer_threshold: 100})
        display_counter_for?(content_module).should be_false
      end

      it "should be false if goal and threshold are set to 0" do
        content_module = mock_module('EmailTargetsModule', emails_sent: 50, options: {thermometer_threshold: 0, emails_goal: 0})
        display_counter_for?(content_module).should be_false
      end
    end

    context "donation module" do
      it "should be true if donations made exceeds threshold" do
        content_module = mock_module('DonationModule', donations_made: 150, options: {thermometer_threshold: 100})
        display_counter_for?(content_module).should be_true
      end

      it "should be false if donations made does not exceed threshold" do
        content_module = mock_module('DonationModule', donations_made: 50, options: {thermometer_threshold: 100})
        display_counter_for?(content_module).should be_false
      end

      it "should be false if donations made does not exceed threshold" do
        content_module = mock_module('DonationModule', donations_made: 50, options: {thermometer_threshold: 0, donations_goal: 0})
        display_counter_for?(content_module).should be_false
      end

      it "should display currency options from one-off settings if available" do
        suggested_amounts = OpenStruct.new
        suggested_amounts.attributes = { 'usd' => "1, 2, 3", 'gbp' => "4, 5, 6", 'cad' => "7, 8, 9" }
        content_module = mock_module('DonationModule', donations_made: 50, options: { suggested_amounts: suggested_amounts, default_currency: 'usd' })

        currency_options = options_for_currency_select(content_module)

        currency_options.should have_tag('option', :with => {:selected => 'selected', :value => 'usd'})
        currency_options.should have_tag('option', :with => {:value => 'gbp'})
        currency_options.should have_tag('option', :with => {:value => 'cad'})
      end

      it "should display currency options from recurring if one-off is not available" do
        monthly_recurring_suggested_amounts = OpenStruct.new
        monthly_recurring_suggested_amounts.attributes = { 'usd' => "1, 2, 3", 'gbp' => "4, 5, 6", 'cad' => "7, 8, 9" }
        recurring_suggested_amounts = OpenStruct.new
        recurring_suggested_amounts.attributes = { 'monthly' => monthly_recurring_suggested_amounts }
        recurring_default_currency = OpenStruct.new
        recurring_default_currency.attributes = { 'monthly' => 'usd' }
        content_module = mock_module('DonationModule', donations_made: 50, 
                                        options: { 
                                            recurring_suggested_amounts: recurring_suggested_amounts, 
                                            recurring_default_currency: recurring_default_currency 
                                      })

        currency_options = options_for_currency_select(content_module)

        currency_options.should have_tag('option', :with => {:selected => 'selected', :value => 'usd'})
        currency_options.should have_tag('option', :with => {:value => 'gbp'})
        currency_options.should have_tag('option', :with => {:value => 'cad'})

        empty_suggested_amounts = OpenStruct.new
        empty_suggested_amounts.attributes = { }
        content_module = mock_module('DonationModule', donations_made: 50, 
                                        options: { 
                                          recurring_suggested_amounts: recurring_suggested_amounts,
                                          recurring_default_currency: recurring_default_currency,
                                          suggested_amounts: empty_suggested_amounts 
                                    })
        currency_options = options_for_currency_select(content_module)

        currency_options.should have_tag('option', :with => {:selected => 'selected', :value => 'usd'})
        currency_options.should have_tag('option', :with => {:value => 'gbp'})
        currency_options.should have_tag('option', :with => {:value => 'cad'})
      end

      it "should display currency options from one-off even if recurring is available" do
        suggested_amounts = OpenStruct.new
        suggested_amounts.attributes = { 'usd' => "1, 2, 3", 'gbp' => "4, 5, 6", 'cad' => "7, 8, 9" }
        monthly_recurring_suggested_amounts = OpenStruct.new
        monthly_recurring_suggested_amounts.attributes = { 'eur' => "10, 20, 30", 'jpy' => "40, 50, 60" }
        recurring_suggested_amounts = OpenStruct.new
        recurring_suggested_amounts.attributes = { 'monthly' => monthly_recurring_suggested_amounts }
        recurring_default_currency = OpenStruct.new
        recurring_default_currency.attributes = { 'monthly' => 'eur' }
        content_module = mock_module('DonationModule', donations_made: 50, 
                                        options: { 
                                            suggested_amounts: suggested_amounts,
                                            default_currency: 'usd',
                                            recurring_suggested_amounts: recurring_suggested_amounts,
                                            recurring_default_currency: recurring_default_currency
                                    })

        currency_options = options_for_currency_select(content_module)

        currency_options.should have_tag('option', :with => {:selected => 'selected', :value => 'usd'})
        currency_options.should have_tag('option', :with => {:value => 'gbp'})
        currency_options.should have_tag('option', :with => {:value => 'cad'})
      end

      it "should return correct frequency option" do
        frequency_options = OpenStruct.new
        frequency_options.attributes = { 'one_off' => 'default', 'monthly' => 'optional' }
        content_module = mock_module('DonationModule',
                                        options: {
                                          frequency_options: frequency_options
                                        })

        default_donation_frequency?(content_module, :one_off).should be_true
        default_donation_frequency?(content_module, :monthly).should be_false

        frequency_options.attributes['one_off'] = 'optional'
        frequency_options.attributes['monthly'] = 'default'

        default_donation_frequency?(content_module, :one_off).should be_false
        default_donation_frequency?(content_module, :monthly).should be_true
      end

      it "should make one_off default frequency if none is available" do
        frequency_options = OpenStruct.new
        frequency_options.attributes = { }
        content_module = mock_module('DonationModule',
                                        options: {
                                          frequency_options: frequency_options
                                        })

        default_donation_frequency?(content_module, :one_off).should be_true
        default_donation_frequency?(content_module, :monthly).should be_false
      end
    end

    it "should be false for non ask modules" do
      content_module = mock_module('JoinModule')
      display_counter_for?(content_module).should be_false
    end

    describe "render_counter_statement_for" do
      context "petiton module" do
        it "should render partial with message for 'steps_taken' if signatures exceeds threshold" do
          content_module = mock_module('PetitionModule', signatures: 150, options: {thermometer_threshold: 100, signatures_goal: 200})
          render_counter_statement_for(content_module).should include "#{t('steps_taken',:counter => 150,:goal => 200,:scope => 'action_taken.PetitionModule')}"
        end

        it "should return if goal and threshold are set to 0" do
          content_module = mock_module('PetitionModule', signatures: 150, options: {thermometer_threshold: 0, signatures_goal: 0})
          render_counter_statement_for(content_module)
          Porpoise::ActionsHelper.should_not_receive(:render)
        end

        it "should render partial with message for 'message_before_threshold_reached' if signatures does not exceed threshold" do
          content_module = mock_module('PetitionModule', signatures: 50, options: {thermometer_threshold: 100, signatures_goal: 200})
          render_counter_statement_for(content_module).should include "#{t('message_before_threshold_reached',:counter => 50,:goal => 200,:scope => 'action_taken.PetitionModule')}"
        end

        it "should render partial with message for 'goal_reached' if the goal is reached" do
          content_module = mock_module('PetitionModule', signatures: 200, options: {thermometer_threshold: 100, signatures_goal: 200})
          render_counter_statement_for(content_module).should include "#{t('goal_reached',:counter => 200,:goal => 200,:scope => 'action_taken.PetitionModule')}"

          content_module = mock_module('PetitionModule', signatures: 250, options: {thermometer_threshold: 100, signatures_goal: 200})
          render_counter_statement_for(content_module).should include "#{t('goal_reached',:counter => 250,:goal => 200,:scope => 'action_taken.PetitionModule')}"
        end
      end

      context "donation module" do
        it "should render partial with message for 'message_before_threshold_reached' if signatures does not exceed threshold" do
          content_module = mock_module('DonationModule', donations_made: 50, options: {thermometer_threshold: 100, :donations_goal => 200})
          render_counter_statement_for(content_module).should include "#{t('message_before_threshold_reached',:counter => 50,:goal => 200,:scope => 'action_taken.DonationModule')}"
        end

        it "should return if goal and threshold are set to 0" do
          content_module = mock_module('DonationModule', donations_made: 50, options: {thermometer_threshold: 0, :donations_goal => 0})
          render_counter_statement_for(content_module)
          Porpoise::ActionsHelper.should_not_receive(:render)
        end

        it "should render partial with message for 'goal_reached' if threshold is reached" do
          content_module = mock_module('DonationModule', donations_made: 200, options: {thermometer_threshold: 100, :donations_goal => 200})
          render_counter_statement_for(content_module).should include "#{t('goal_reached',:counter => 200,:goal => 200,:scope => 'action_taken.DonationModule')}"
        end

        it "should render partial with message for 'message_before_threshold_reached' if signatures does not exceed threshold" do
          content_module = mock_module('TaxDeductibleDonationModule', donations_made: 50, options: {thermometer_threshold: 100, :donations_goal => 200})
          render_counter_statement_for(content_module).should include "#{t('message_before_threshold_reached',:counter => 50,:goal => 200,:scope => 'action_taken.TaxDeductibleDonationModule')}"
        end

        it "should render partial with message for 'goal_reached' if the threshold is reached" do
          content_module = mock_module('TaxDeductibleDonationModule', donations_made: 200, options: {thermometer_threshold: 100, :donations_goal => 200})
          render_counter_statement_for(content_module).should include "#{t('goal_reached',:counter => 200,:goal => 200,:scope => 'action_taken.TaxDeductibleDonationModule')}"
        end
      end

      context "email targets module" do
        it "should render partial with message for 'steps_taken' if signatures exceeds threshold" do
          content_module = mock_module('EmailTargetsModule', emails_sent: 150, options: {thermometer_threshold: 100, emails_goal: 200})
          render_counter_statement_for(content_module).should include "#{t('steps_taken',:counter => 150,:goal => 200,:scope => 'action_taken.EmailTargetsModule')}"
        end

        it "should return if goal and threshold are set to 0" do
          content_module = mock_module('EmailTargetsModule', emails_sent: 150, options: {thermometer_threshold: 0, emails_goal: 0})
          render_counter_statement_for(content_module)
          Porpoise::ActionsHelper.should_not_receive(:render)
        end

        it "should render partial with message for 'message_before_threshold_reached' if signatures does not exceed threshold" do
          content_module = mock_module('EmailTargetsModule', emails_sent: 50, options: {thermometer_threshold: 100, emails_goal: 200})
          render_counter_statement_for(content_module).should include "#{t('message_before_threshold_reached',:counter => 50,:goal => 200,:scope => 'action_taken.EmailTargetsModule')}"
        end

        it "should render partial with message for 'goal_reached' if the goal is reached" do
          content_module = mock_module('EmailTargetsModule', emails_sent: 200, options: {thermometer_threshold: 100, emails_goal: 200})
          render_counter_statement_for(content_module).should include "#{t('goal_reached',:counter => 200,:goal => 200,:scope => 'action_taken.EmailTargetsModule')}"

          content_module = mock_module('EmailTargetsModule', emails_sent: 250, options: {thermometer_threshold: 100, emails_goal: 200})
          render_counter_statement_for(content_module).should include "#{t('goal_reached',:counter => 250,:goal => 200,:scope => 'action_taken.EmailTargetsModule')}"
        end
      end
    end
  end

  describe "#labeled_field_group" do
    it "should render nothing if the given object doesn't respond to the given method" do
      labeled_field_group(Object.new, :foo).should be_nil
    end

    it "should render nothing if the given field should be hidden" do
      labeled_field_group(double(:foo => 'hidden'), :foo).should be_nil
    end

    it "should render a field wrapper and yield false if the given field is optional" do
      wrapper, is_required = nil, nil
      wrapper = labeled_field_group(double(:foo => 'optional'), :foo) { |req| is_required = req }

      wrapper.should == "<p class=\"field_wrapper foo \"></p>"
      is_required.should be_false
    end

    it "should render a field wrapper and yield true if the given field is required" do
      wrapper, is_required = nil, nil
      wrapper = labeled_field_group(double(:foo => 'required'), :foo) { |req| is_required = req }

      wrapper.should == "<p class=\"field_wrapper foo \"></p>"
      is_required.should be_true
    end
  end

  def mock_module(type, params={})
    mock('module', params.merge(type: type, options: OpenStruct.new(params.delete(:options))))
  end
end

