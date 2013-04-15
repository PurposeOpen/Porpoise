module Porpoise
  class HomeController < ApplicationController
    remote_resource_class Platform::Movement

    caches_action :index, :expires_in => AppConstants.action_caching_expiration, :cache_path => lambda { |c|
      c.params.delete_if { |p| p == 't' }
    }


    def index
      @member = Platform::Member.new
      render
    end

    def preview
      @member = Platform::Member.new
      @movement = Platform::Movement.find(Platform.movement_id, :params => params.slice(:draft_homepage_id)) #.merge(:locale=>I18n.locale))
      render :preview
    end

    def redirect
      if request.fullpath.match(/^\/\w{2}\//) 
        raise ActionController::RoutingError, "Route not found for #{request.fullpath}"
      else
        redirect_to [ "/", I18n.locale, request.fullpath ].join
      end
    end
  end
end
