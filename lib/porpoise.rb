require 'app_constants'
require 'purpose_country_select'
require 'rack-timeout'
require 'open-uri'
require 'porpoise/engine'

module Platform
  class << self
    DEFAULT_CACHE_EXPIRATION = 5 * 60

    attr_writer :password, :movement_id, :movement_name, :cache_expiration

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
      @full_uri = nil
    end

    def full_uri
      @full_uri ||= [ self.base_uri.gsub(/\/$/, ''), 'movements', self.movement_id ].join('/')
    end

    def movement_name
      @movement_name ||= ENV['MOVEMENT_NAME']
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
      Platform::Movement.site = self.base_uri
      Platform::Base.site = self.full_uri
      Platform::Base.user = self.movement_id
      Platform::Base.password = self.password
    end
  end

end
