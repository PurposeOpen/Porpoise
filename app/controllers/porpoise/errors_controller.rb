module Porpoise
  class ErrorsController < ApplicationController
    def page_not_found
      ::Rails.logger.error env["action_dispatch.exception"].try(:backtrace)
      redirect_to AppConstants.page_not_found_url
    end

    def went_wrong
      redirect_url = homepage? ? AppConstants.homepage_error_url : AppConstants.error_url
      ::Rails.logger.error env["action_dispatch.exception"].try(:backtrace)
      redirect_to redirect_url
    end

    private

    def homepage?
      params[:controller] == 'home' && params[:action] == 'index'
    end
  end
end