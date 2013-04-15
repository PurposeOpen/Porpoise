require "rails"

module Platform
  class Engine < ::Rails::Engine
    initializer 'platform.set_session_token' do |app|
      app.config.session_store :cookie_store, key: "_#{ENV['MOVEMENT_ID']}_session"
    end
  end
end
