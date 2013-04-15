module Porpoise
  class ActivitiesController < ApplicationController
    BASE_URI = "#{Platform.base_uri}movements/#{Platform.movement_id}/activity.json"

    skip_before_filter :set_locale_load_content
    caches_action :show, :expires_in => 5.minutes, :cache_path => lambda { |_|
      request.fullpath
    }

    def show
      # Proxy the activity feed so we don't have to expose anything about the platform API.
      response = open_on_platform(BASE_URI + "?#{request.query_string}", "Accept-Language" => params[:locale])

      self.response_body = response
      self.response.headers["Content-Type"] = response.meta['content-type']
      self.response.headers["Content-Language"] = response.meta['content-language']
      self.response.headers["Expires"] = response.meta['expires']
    end
  end
end

