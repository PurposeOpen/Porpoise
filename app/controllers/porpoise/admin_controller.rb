module Porpoise
  class AdminController < ApplicationController
    include PlatformCommunicationHelper
    protect_from_forgery
  end
end

