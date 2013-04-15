class Admin::HealthDashboardController < ActionController::Base
  include PlatformCommunicationHelper

  def index
    begin
      response = get_on_platform("#{Platform.base_uri}movements/#{Platform.movement_id}/awesomeness.json")
      if response.code.to_i == 200
        json = JSON.parse(response.body)
        @service_statuses = build_platform_status(json['services']['platform'])
      else
        @service_statuses = build_platform_status("WARNING - Invalid response (#{response.code})")
      end
    rescue Exception => e
      @service_statuses = build_platform_status("CRITICAL - Connection error: #{e.message}")
    end

    render :json => @service_statuses
  end

  def build_platform_status(msg)
    {
        services: {
            platform: msg
        }
    }
  end
  private :build_platform_status
end
