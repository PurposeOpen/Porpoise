require 'optparse'

class ::AppBuilder < Rails::AppBuilder
  def config
    super
    inside("config") do
      create_constants_file
      inside "environments" do
        add_porpoise_assets_to_precompilation
      end
    end
  end

  def app
    super
    system("rm -rf app/views/layouts")
    system("rm app/assets/stylesheets/application.css")
    system("rm app/assets/javascripts/application.js")
    system("rm app/controllers/application_controller.rb")
  end

  def gemfile
    super
    add_porpoise
  end

  def leftovers
    create_env_file
    system("rm public/index.html")
  end

  private

  def add_porpoise
    existing_contents = File.readlines('Gemfile')
    existing_contents << "gem 'porpoise', :git => 'git://github.com/PurposeOpen/Porpoise.git', :tag => 'v0.8.7'\n"
    existing_contents << "gem 'money'\n"
    existing_contents << "gem 'uuid'\n"
    existing_contents << "gem 'purpose_country_select', :git => 'https://github.com/PurposeOpen/country_select.git'\n"
    File.write('Gemfile', existing_contents.join)
  end

  def get_options
    options = {:movement_id => app_name, :movement_name => app_name, :movement_password => app_name}
    OptionParser.new do |opts|
      opts.on("--movement_name NAME", String, "NAME is the name of the movement"){ |n| options[:movement_name] = n }
      opts.on("--movement_id ID", String, "ID is the id of the movement"){ |n| options[:movement_id] = n }
      opts.on("--movement_password PASSWORD", String, "PASSWORD is the password of the movement"){ |n| options[:movement_password] = n }
      opts.parse!(ARGV.select{|x| x =~ /\A--movement/})
    end
    options
  end

  def create_env_file
    options = get_options
    create_file '.env', <<-ENV
export MOVEMENT_ID=#{options[:movement_id]}
export MOVEMENT_NAME='#{options[:movement_name]}'
export MOVEMENT_BASIC_AUTH_PASSWORD=#{options[:movement_password]}
export ACTION_CACHING_EXPIRATION=0
export PLATFORM_BASE_URI="http://localhost:5000/api"
    ENV
  end

  def create_constants_file
      create_file 'constants.yml', <<-CONSTANTS
development: &default
  action_caching_expiration: <%= 5.minutes %>
  google_tracking_id: <%= ENV["GOOGLE_TRACKING_ID"] %>
  homepage_error_url: "A homepage error url"
  error_url: "An error url"
  page_not_found_url: "A page not found url"
  web_timeout: 200
production:
  <<: *default
  web_timeout: 90

staging:
  <<: *default
  web_timeout: 90

test:
  <<: *default
  platform_base_uri:  "http://example.com/api/"
  movement_id: "testmovement"
  auth_password: "testmovement"
  web_timeout: 90
      CONSTANTS
  end

  def add_porpoise_assets_to_precompilation
    production_config = File.read('production.rb')
    production_config = production_config.gsub(/# config\.assets\.precompile \+= %w\( search\.js \)/, 'config.assets.precompile += %w( porpoise/libs/modernizr.js )')
    File.write('production.rb', production_config)
  end
end
