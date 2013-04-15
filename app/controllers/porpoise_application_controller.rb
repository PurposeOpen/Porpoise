class PorpoiseApplicationController < ActionController::Base
  include PlatformCommunicationHelper

  protect_from_forgery
  rescue_from ActiveResource::ResourceNotFound, :with => :handle_resource_not_found

  class_attribute :remote_resources
  self.remote_resources = [Platform::Movement]

  prepend_before_filter :track_email_click
  prepend_before_filter :set_locale_load_content
  prepend_before_filter :render_maint_if_pre_launch

  protected

  ANY_LANGUAGE = '*'


  def track_email_click
    if(params[:t].present?)
      email_tracking_uri = "#{Platform.base_uri}movements/#{Platform.movement_id}/email_tracking/email_clicked"
      post_to_platform(email_tracking_uri, email_tracking_params)
    end
  end

  def set_locale_load_content
    if params[:locale].blank?
      set_accept_language_headers ANY_LANGUAGE
      load_movement_content
      params[:locale] = (@available_languages.select { |lang| lang.is_default == true})[0].iso_code
      set_locale(params[:locale])
    else
      set_locale(params[:locale])
      set_accept_language_headers I18n.locale.to_s
      load_movement_content
    end
    # FIXME: Need to set Globalize.locale if we use Globalize3
  end

  def set_locale(param)
    I18n.locale = param
    headers["Content-Language"] = param
  end

  def load_movement_content
    @movement = Platform::Movement.find(Platform.movement_id) #, :params=>{:locale=>I18n.locale})
    @available_languages = @movement.languages
    @recommended_languages_to_display = @movement.recommended_languages_to_display
  end

  #TODO: BUG: NOT THREADSAFE OR EVEN SAFE!!! Look at Platform::Base.headers to see current thread fix but should still look for something else?
  def set_accept_language_headers(accept_language)
    self.remote_resources.each do |resource|
      resource.headers['Accept-Language'] = accept_language
      resource.headers['X-Original-Request-UUID'] = request.uuid unless Rails.env.test?
      resource.headers['X-Original-Request-IP'] = request.ip unless Rails.env.test?
    end
  end

  def self.remote_resource_class(klass)
    self.remote_resources << klass unless self.remote_resources.include? klass
  end

  def handle_resource_not_found(error)
    redirect_to(root_path(:locale => I18n.locale))
  end

  private

  def email_tracking_params
    params.slice(:t).tap do |tracking_params|
      if tracking_params.any?
        case params[:controller]
          when ActionsController.controller_path
            tracking_params.merge! :page_type => "ActionPage", :page_id => params[:id]
          when ContentPagesController.controller_path
            tracking_params.merge! :page_type => "ContentPage", :page_id => params[:content_page]
          when HomeController.controller_path
            tracking_params.merge! :page_type => "Homepage"
        end
      end
    end
  end

  def render_maint_if_pre_launch
    render :text => maintenance_page, :layout => false if request_is_public_facing? && pre_launch?
  end

  def maintenance_page
    Rails.cache.fetch("#{Platform.movement_id}.maintenance_page", :expires_in => 5.minutes) do
      open(maintenance_page_url).read
    end
  end

  def pre_launch?
    ENV["PRE_LAUNCH"].present?
  end

  def maintenance_page_url
    ENV["MAINTENANCE_PAGE_URL"]
  end

  def request_is_public_facing?
     request.env['SERVER_NAME'] =~ /#{Platform.movement_id}\.org/
  end
end
