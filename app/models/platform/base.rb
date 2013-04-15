class Platform::Base < ActiveResource::Base
  self.format = :json

  class << self
  
    #TODO: This should make headers threadsafe, let's hope because query strings don't work on .new etc
    def headers
      Thread.current["active.resource.thread.current.headers"] = {} if Thread.current["active.resource.thread.current.headers"].blank?
      Thread.current["active.resource.thread.current.headers"]
    end  
    
    def cache!(opts={})
      @cached = false #true
      @expiry_time = opts[:expires_in] || Platform.cache_expiration
      #Rails.logger.warn "Cache! is currently disabled due to thread issues for #{self.name}" if defined?(Rails)
    end

    def should_be_cached?
      !!@cached
      false
    end

    def expiry_time; @expiry_time; end

    private

    # Moved caching in here because ActiveResource objects cannot be reliably cached. Instead, we are caching the 'payload'
    # so that ActiveResource can still create classes on-the-fly
    def find_single(scope, options)
      if self.should_be_cached? #DISABLED CURRENTLY, REMOVE THIS NOTICE IF CHANGING cache! and should_be_cached? to ENABLE
        key = "#{self.name}/#{scope.inspect}/#{options.inspect}/#{headers.inspect}"
        attributes_and_options = Rails.cache.fetch(key, expires_in: self.expiry_time) do
          #headers['X-ORIGINAL-REQUEST-UUID']='XXXX'
          #Rails.logger.debug headers.inspect
          prefix_options, query_options = split_options(options[:params])
          path = element_path(scope, prefix_options, query_options)
          [format.decode(connection.get(path, headers).body), prefix_options]
        end
        instantiate_record(attributes_and_options[0], attributes_and_options[1])
      else
        super
      end
    end
  end
end
