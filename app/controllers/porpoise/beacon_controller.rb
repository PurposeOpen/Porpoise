module Porpoise
  class BeaconController < ApplicationController
    BASE_URI = "#{Platform.base_uri}movements/#{Platform.movement_id}/email_tracking/"

    skip_before_filter :set_locale_load_content
    skip_before_filter :track_email_click

    def send_beacon_gif
      send_data(Base64.decode64("R0lGODlhAQABAPAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw=="), :type => "image/gif", :disposition => "inline")
    end

    def index
      email_tracking_hash = params[:t]
      return send_beacon_gif unless email_tracking_hash
      open_on_platform(BASE_URI + "email_opened?t=#{email_tracking_hash}")
      send_beacon_gif
    end
  end
end
