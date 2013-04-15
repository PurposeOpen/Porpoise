module Porpoise
  class SharesController < ApplicationController
    skip_before_filter :set_locale_load_content

    API_SHARE_URL = "#{Platform.base_uri}movements/#{Platform.movement_id}/shares"

    def create
      response = post_to_platform(API_SHARE_URL, params)
      head response.code
    end
  end
end