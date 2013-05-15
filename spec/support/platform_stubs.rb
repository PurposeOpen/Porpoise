# coding: utf-8
module PlatformStubs

  DEFAULT_LANGUAGE = 'en'

  def stub_languages
    return {
      "pt" => {:iso_code => "pt", :native_name => "Português", :name => "Portuguese", :is_default => false},
      "it" => {:iso_code => "it", :native_name => "Italiano", :name => "Italian", :is_default => false},
      "en" => {:iso_code => "en", :native_name => "English", :name => "English", :is_default => false}
    }
  end

  def stub_movement(default_language = DEFAULT_LANGUAGE)
    languages = stub_languages
    languages[default_language][:is_default] = true

    return {
      :banner_image => "banner_image.png",
      :banner_text => "Default greeting",
      :join_headline => "Join Headline",
      :join_message => "Join message",
      :follow_links => {:facebook => 'http://facebook.com', :twitter => 'http://twitter.com'},
      :languages => languages.values,
      :recommended_languages_to_display => languages.values,
      :header_navbar => "<ul><li><a href='#'>A header link</a></li></ul>",
      :footer_navbar => "<ul><li><a href='#'>A footer link</a></li></ul>",
      :featured_contents => {'Carousel' => [], 'FeaturedActions' => []}
    }
  end

  def stub_movement_request(default_language = DEFAULT_LANGUAGE)
    Rails.cache.clear
    content = stub_movement(default_language)
    FakeWeb.register_uri :get, %r[http://testmovement:testmovement@example.com/api/#{default_language}/movements/testmovement.json], :body => {:content => content}.to_json
  end

  def stub_create_member(options={})
    Rails.cache.clear
    status = options[:status] || 201
    body = options[:body] || {}
    FakeWeb.register_uri(:post, %r[http://testmovement:testmovement@example.com/api/movements/testmovement/members], :status => status, :body => body.to_json)
  end

  def stub_platform_health_check(options={})
    Rails.cache.clear
    status = options[:status] || 200
    body = options[:body] || {'services' => {'platform' => 'OK'}}
    FakeWeb.register_uri(:get, %r[http://testmovement:testmovement@example.com/api/movements/testmovement/awesomeness.json], :status => status, :body => body.to_json)
  end

  def recursive_merge(original_hash, other_hash)
    r = {}
    original_hash.merge(other_hash)  do |key, oldval, newval|
      r[key] = oldval.class == Hash ? recursive_merge(oldval, newval) : newval
    end
  end
end
