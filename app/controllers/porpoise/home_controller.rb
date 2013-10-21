module Porpoise
  class HomeController < ApplicationController
    remote_resource_class Platform::Movement

    after_filter :allow_preview_from_other_domains, only: :preview

    def index
      fetch_cache(request.path) do
        @member = Platform::Member.new
        render
      end
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
