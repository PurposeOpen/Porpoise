require 'spec_helper'

describe 'TestApplicationControllerWithoutResource' do
  controller do
    def create; head :ok; end

    def show
      raise ActiveResource::ResourceNotFound.new(OpenStruct.new(:code => 404))
    end

    def error_action
      raise "error"
    end

  end

  before :each do
    stub_movement_request
  end

  it "should not break" do
    post :create, :locale => 'pt'
    response.should be_success
  end
end

describe HomeController, "TestApplicationControllerWithoutResource" do
  it "should redirect to homepage on resource not found error" do
    Platform::Member.should_receive(:new).and_raise(ActiveResource::ResourceNotFound.new("as"))
    stub_movement_request
    get :index, :locale => "en"
    response.should redirect_to(root_path(:locale => I18n.locale))
  end
end

describe ApplicationController do
  controller do
    def index; head :ok; end
  end

  before do
    stub_movement_request
  end

  it "should redirect to the maintenance page URL if the PRE_LAUNCH setting is true and we're coming from a public-facing domain" do
    ENV["MAINTENANCE_PAGE_URL"] = "http://example.com/maint.html"
    controller.should_receive(:open).with("http://example.com/maint.html").and_return(stub(:read => 'coming soon'))
    ENV["PRE_LAUNCH"] = "true"
    request.env["SERVER_NAME"] = "testmovement.org"

    get :index

    response.body.should == "coming soon"

    request.env["SERVER_NAME"] = "www.testmovement.org"

    get :index

    response.body.should == "coming soon"
  end

  it "should not redirect if the PRE LAUNCH setting is false or not set and we're coming from a public-facing domain" do
    ENV["PRE_LAUNCH"] = ""
    request.env["SERVER_NAME"] = "testmovement.org"

    get :index
    response.body.should be_blank
  end

  it "should not redirect if the PRE_LAUNCH setting is true and we're not coming from a public-facing domain" do
    ENV["PRE_LAUNCH"] = "true"
    request.env["SERVER_NAME"] = "testmovement-production.herokuapp.com"

    get :index
    response.body.should be_blank
  end

end

class TestResource < ActiveResource::Base
end

describe 'TestApplicationControllerWithResource' do
  controller do
    remote_resource_class TestResource
    def show; head :ok; end
    def create; head :ok; end
  end

  before :each do
    stub_movement_request('en')
  end

  it "should default the Accept-Language header to en for every resource" do
    I18n.locale = ''
    post :create

    TestResource.headers['Accept-Language'].should eql '*'
  end

  it "should set the Accept-Language header based on the request for every resource" do
    post :create, :locale => 'it'

    TestResource.headers['Accept-Language'].should eql "it"
  end

  it "should set default language", :type => :request do
    stub_movement_request("pt")

    get :show, :id => 'testmovement id'

    response.headers['Content-Language'].should == 'pt'
  end
end

