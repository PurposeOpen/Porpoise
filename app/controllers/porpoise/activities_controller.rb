module Porpoise
  class ActivitiesController < ApplicationController

    skip_before_filter :set_locale_load_content
    before_filter :set_locale_without_default

    caches_action :show, :expires_in => 5.minutes, :cache_path => lambda { |_|
      request.fullpath
    }

    def show
      # Proxy the activity feed so we don't have to expose anything about the platform API.
      base_uri = "#{Platform.base_uri}/#{I18n.locale}/movements/#{Platform.movement_id}/activity.json"
      response = open_on_platform(base_uri + "?#{request.query_string}")

      self.response_body = response
      self.response.headers["Content-Type"] = response.meta['content-type']
      self.response.headers["Content-Language"] = response.meta['content-language']
      self.response.headers["Expires"] = response.meta['expires']
    end

    private

    def set_locale_without_default
      set_locale(params[:locale])
    end

  end
end

