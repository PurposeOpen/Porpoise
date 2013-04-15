module PlatformCommunicationHelper

  def open_on_platform(url, options = {})
    if !Rails.env.test?
      default_options = {
        'X-Original-Request-UUID' => request.uuid,
        'X-Original-Request-IP' => request.ip
      }.merge(options)
    else
      default_options = options 
    end
  
    open(url, { :http_basic_authentication => [Platform.movement_id, Platform.password] }.merge(default_options || {}))
  end

  def get_on_platform(url)
    do_request(url, :get)
  end

  def post_to_platform(url, params)
    do_request(url, :post, params)
  end

  private

  REQUEST_TYPES = {
    :get => Net::HTTP::Get,
    :post => Net::HTTP::Post
  }

  def do_request(url, method, params = nil)
    uri = URI.parse(url)

    req = REQUEST_TYPES[method].new(uri.path)
    req.basic_auth(Platform.movement_id, Platform.password)
    req.form_data = params if params
    
    unless Rails.env.test?
      req['X-Original-Request-UUID'] = request.uuid
      req['X-Original-Request-IP'] = request.ip
    end

    sock = Net::HTTP::new(uri.host, uri.port)
    sock.use_ssl = true if url.downcase.starts_with?("https")

    sock.request(req)
  end

end