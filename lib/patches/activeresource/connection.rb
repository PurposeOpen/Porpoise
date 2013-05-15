module ActiveResource
	class Connection
    # The path segment from the 'site' URL is ignored by default on ActiveResource, so setting the site
    # attribute to something like https://platform.com/api/ would make ARes requests to be made to https://platform.com/
    # This patch allows to set a path on the site attribute
		def request(method, path, *arguments)
      result = ActiveSupport::Notifications.instrument("request.active_resource") do |payload|
        payload[:method]      = method

        payload[:request_uri] = "#{site.scheme}://#{site.host}:#{site.port}#{site.path}#{path}"
        payload[:result]      = http.send(method, "#{site.path}#{path}", *arguments)
      end
      handle_response(result)
    rescue Timeout::Error => e
      raise TimeoutError.new(e.message)
    rescue OpenSSL::SSL::SSLError => e
      raise SSLError.new(e.message)
    end
  end
end