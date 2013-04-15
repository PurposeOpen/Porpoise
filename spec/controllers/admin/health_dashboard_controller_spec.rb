require 'spec_helper'

describe Admin::HealthDashboardController do
  describe "json" do
    it "should be critical if the platform is unreachable" do
      Net::HTTP.any_instance.should_receive(:request).and_raise(Exception.new "Errno::EHOSTUNREACH: No route to host - connect(2)")

      get :index, :format => 'json'

      services = JSON.parse(response.body)['services']
      services['platform'].should eql "CRITICAL - Connection error: Errno::EHOSTUNREACH: No route to host - connect(2)"

    end

    it "should be critical if the platform returns an invalid response" do
      stub_platform_health_check(:status => 403)

      get :index, :format => 'json'

      services = JSON.parse(response.body)['services']
      services['platform'].should eql "WARNING - Invalid response (403)"
    end

    it "should show the platform is critical during a Zombie Apocalypse" do
      stub_platform_health_check(:body => {'services' => {'platform' => 'CRITICAL - Zombie Attack!'}})

      get :index, :format => 'json'

      services = JSON.parse(response.body)['services']
      services['platform'].should eql "CRITICAL - Zombie Attack!"
    end


    it "should show the platform is OK" do
      stub_platform_health_check(:body => {'services' => {'platform' => 'OK'}})

      get :index, :format => 'json'

      services = JSON.parse(response.body)['services']
      services['platform'].should eql "OK"
    end

    def stub_platform_health_check(options={})
      status = options[:status] || 200
      body = options[:body] || {'services' => {'platform' => 'OK'}}
      FakeWeb.register_uri(:get, %r[http://testmovement:testmovement@example.com/api/movements/testmovement/awesomeness.json], :status => status, :body => body.to_json)
    end
  end
end
