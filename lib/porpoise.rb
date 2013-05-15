require 'app_constants'
require 'rack-timeout'
require 'open-uri'
require 'porpoise/engine'

module Platform
  class << self
    DEFAULT_CACHE_EXPIRATION = 5 * 60

    attr_writer :password, :movement_id, :movement_name, :cache_expiration, :default_language

    def password
      @password ||= ENV['MOVEMENT_BASIC_AUTH_PASSWORD']
    end

    def movement_id
      @movement_id ||= ENV['MOVEMENT_ID']
    end

    def base_uri
      if @base_uri.blank?
        self.base_uri = ENV['PLATFORM_BASE_URI']
      end
      @base_uri
    end

    def base_uri=(uri)
      @base_uri = uri
    end

    def movement_name
      @movement_name ||= ENV['MOVEMENT_NAME']
    end

    def default_language
      @default_language ||= ENV['DEFAULT_LANGUAGE']
    end

    def cache_expiration
      if @cache_expiration.blank?
        self.cache_expiration = ENV["ACTION_CACHING_EXPIRATION"].try(:to_i) || DEFAULT_CACHE_EXPIRATION
      end
      @cache_expiration
    end

    def cache_expiration=(time)
      @cache_expiration = time.to_i.seconds
    end

    def configure
      yield self if block_given?
      self.send(:apply_config)
    end

    private

    def apply_config
      Platform::Base.site = self.base_uri

      Platform::Base.prefix = "movements/#{self.movement_id}/"
      Platform::LocalizableResource.prefix = ":locale/movements/#{self.movement_id}/"
      Platform::Movement.prefix = ':locale/'

      Platform::Base.user = self.movement_id
      Platform::Base.password = self.password
    end
  end

end
