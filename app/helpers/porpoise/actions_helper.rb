module Porpoise::ActionsHelper
  ASK_MODULES = ["PetitionModule", "EmailTargetsModule", "DonationModule", "TaxDeductibleDonationModule", "NonTaxDeductibleDonationModule"]

  CREDIT_CARD_OPTIONS = [['Visa', 'visa'], ['MasterCard', 'master'], ['American Express', 'american_express'], ['Discover', 'discover']]

  COUNTER_PROPERTY_PER_MODULE = {
    'PetitionModule' => :signatures,
    'EmailTargetsModule' => :emails_sent,
    'DonationModule' => :donations_made,
    'TaxDeductibleDonationModule' => :donations_made,
    'NonTaxDeductibleDonationModule' => :donations_made,
  }

  TELL_A_FRIEND_MODULE = 'TellAFriendModule'

	def render_partial_for(content_module, member)
		render :partial => partial_for(content_module), :locals => {:content_module => content_module, :member => member}
	end

  def partial_for(content_module)
    return 'disabled' if content_module.options.respond_to?(:active) and content_module.options.active == 'false'
    {
      "PetitionModule" => 'petition',
      "JoinModule" => 'join',
      "TellAFriendModule" => 'taf',
      "HtmlModule" => 'generic',
      "AccordionModule" => 'generic',
      "UnsubscribeModule" => 'unsubscribe',
      "DonationModule" => 'donation',
      "TaxDeductibleDonationModule" => 'donation',
      "NonTaxDeductibleDonationModule" => 'donation',
      "EmailTargetsModule" => 'email_targets'
    }[content_module.type]
  end

  def fb_share_url(fb_title, share_url)
    "http://www.facebook.com/sharer.php?" + { u: share_url, t: fb_title }.to_param
  end

  def share_count(action_content, share_type)
    format_share_count(action_content.shares.attributes[share_type])
  end

  def user_id_from_session
    "data-user-id='#{session[:member_id]}'" if session[:member_id].present?
  end

  def format_share_count(count)
    if count > 999
      "#{count/1000}K"
    else
      count
    end
  end

  def taf_button_url(share_url, share_channel)
    raw_share_url = raw(share_url)
    href = raw("href='#{raw_share_url}'")

    if !Rails.env.development?
      href << raw(" onclick=\"recordOutboundLink(this, 'TAF - #{share_channel}', '#{request.params[:id]}');return false;\"")
    end

    href
  end

  def with_ask_module(sidebar_content_modules)
    content_module = sidebar_content_modules.find { |mod| ASK_MODULES.include?(mod.type) }
    yield content_module if content_module
  end

  def with_petition_module(sidebar_content_modules)
    content_module = sidebar_content_modules.find { |mod| mod.type == "PetitionModule" }
    yield content_module if content_module
  end

  def get_counter_module(sidebar_content_modules)
    ask_module = sidebar_content_modules.find { |mod| ASK_MODULES.include?(mod.type) }
    taf_module = sidebar_content_modules.find { |mod| TELL_A_FRIEND_MODULE == mod.type }
    ask_module || (action_counter_module(taf_module) if taf_module)
  end

  def display_counter_for?(content_module)
    threshold = (content_module.options.try(:thermometer_threshold).try(:to_i) || 0)
    counter_property = COUNTER_PROPERTY_PER_MODULE[content_module.type]
    return false if (!counter_property || counter_disabled?(threshold, get_counter_and_goal_for(content_module)[:goal]))
    counter_value = content_module.respond_to?(counter_property) ? content_module.send(counter_property).to_i : -1
    counter_value >= threshold
  end

  def render_counter_for(content_module)
    render :partial => "counter", :locals => get_counter_and_goal_for(content_module).merge({:action_module => content_module.type})
  end

  def render_counter_statement_for(content_module)
    goal,counter = lambda{ hash = get_counter_and_goal_for(content_module); return hash[:goal], hash[:counter]}.call
    threshold = (content_module.options.try(:thermometer_threshold).try(:to_i) || 0)
    return if counter_disabled?(threshold, goal)
    message = display_counter_for?(content_module) ? (counter.to_i >= goal.to_i ? 'goal_reached' : 'steps_taken') : 'message_before_threshold_reached'
    render :partial => "counter_statement", :locals => {:message => message, :counter => counter, :goal => goal, :action_module => content_module.type}
  end

  def display_action_feed_for?(content_module)
    ASK_MODULES.include?(content_module.type)
  end

  def comments_enabled?(content_module)
    option_enabled?(:comments, content_module)
  end

  def option_enabled?(option_name, content_module)
    flag = "#{option_name}_enabled"
    return false unless content_module.options.respond_to?(flag)
    flag_value = content_module.options.send(flag)
    flag_value == '1' || flag_value == true
  end

  def email_editing_disabled?(content_module)
    not (content_module.options.allow_editing == '1')
  end

  def default_donation_frequency?(donation_module, frequency)
    frequency_option = donation_module.options.frequency_options.attributes[frequency.to_s]

    return (frequency_option == 'default') unless frequency_option.nil?

    # If frequency option is not available, make one_off default
    return frequency.to_s == 'one_off'
  end

  def options_for_currency_select(donation_module)
    # suggested_amounts example:
    # { :attributes =>
    #     { 
    #         "aud" => "1, 2, 3", 
    #         "cad" => "4, 5" 
    #     }
    # }
    #
    # recurring_suggested_amounts example: 
    # { :attributes => 
    #     { 'monthly' => 
    #         { :attributes => 
    #             { 
    #                 "aud" => "1, 2, 3", 
    #                 "cad" => "4, 5" 
    #             } 
    #         }
    #      } 
    # }
    suggested_amounts = donation_module.options.suggested_amounts.try(:attributes) && donation_module.options.suggested_amounts.attributes.count > 0 ? 
                          donation_module.options.suggested_amounts :
                          donation_module.options.recurring_suggested_amounts.attributes.first[1]
    default_currency = donation_module.options.respond_to?(:default_currency) ? 
                          donation_module.options.default_currency : 
                          donation_module.options.recurring_default_currency.attributes.first[1]

    options = suggested_amounts.attributes.keys.map do |currency_code|
      [t("actions.donations.currencies.#{currency_code.downcase}"), currency_code]
    end

    options_for_select(options, default_currency)
  end

  def options_for_card_type_select
    select_options_with_label(t("actions.donations.card_type"), CREDIT_CARD_OPTIONS)
  end

  def options_for_month_select
    select_options_with_label(t('actions.donations.month'), (1..12).map { |m| '%02d' % m }.to_a)
  end

  def options_for_year_select
    current_year = Time.current.year
    select_options_with_label(t('actions.donations.year'), (current_year..current_year + 20).to_a)
  end

  def field_hidden?(field_setting)
    field_setting == 'hidden'
  end

  def field_visible?(field_setting); !field_hidden?(field_setting); end

  def field_required?(field_setting)
    field_setting == 'required'
  end

  def labeled_field_group(action_content, field_name, options = {})
    if action_content.respond_to?(field_name)
      field_setting = action_content.send(field_name)

      if field_visible?(field_setting)
        field_tag field_name, options do
          yield(field_required?(field_setting))
        end
      end
    end
  end

  def field_tag(field_name, options={}, &block)
    content_tag(:p, { :class => "field_wrapper #{field_name} #{options[:class]}" }, &block)
  end

  def goal_tag(goal_val, &block)
    options = {:id => "goal"}
    options = options.merge({:class => "hidden"}) if goal_val == 0
    content_tag(:div, options, &block)
  end

  private

  def get_counter_and_goal_for(content_module)
    if content_module.type == "PetitionModule"
      return {:counter => content_module.signatures, :goal => content_module.options.signatures_goal}
    elsif content_module.type == "EmailTargetsModule"
      return {:counter => content_module.emails_sent, :goal => content_module.options.emails_goal}
    elsif ["DonationModule", "TaxDeductibleDonationModule", "NonTaxDeductibleDonationModule"].include? content_module.type
      return {:counter => content_module.donations_made, :goal => content_module.options.donations_goal}
    end
  end

  def counter_disabled? (threshold, goal)
    return true if (goal == 0 && threshold == 0)
    false
  end

  def select_options_with_label(label, options, default = '')
    options_for_select([[label, '']] + options, :disabled => '', :selected => default)
  end

  def action_counter_module(content_module)
    return unless has_counter_module?(content_module)
    action_counter_page = Platform::ActionPage.find_preview(content_module.options.action_counter_page_id)
    action_counter_page.sidebar_content_modules.first
  end

  def has_counter_module?(content_module)
    content_module.options.include_action_counter == 'true'
  end
end
