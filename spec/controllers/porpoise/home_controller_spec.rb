require 'spec_helper'

describe HomeController do
  it "should return movement" do
    content = stub_movement.merge(:message => "Happy body")
    FakeWeb.register_uri :get, "http://testmovement:testmovement@example.com/api/en/movements/testmovement.json",
                         :body => { :content => content }.to_json
    I18n.stub(:available_locales).and_return [:en, :fr]

    get :index, :locale => "en"

    assigns[:movement].join_headline.should eql "Join Headline"
    assigns[:movement].join_message.should eql "Join message"
    assigns[:movement].message.should eql "Happy body"
    response.headers['Content-Language'].should eql 'en'
    response.should render_template "home/index"
  end

  it "should return movement for preview" do
    stub_movement_request
    FakeWeb.register_uri :get, "http://testmovement:testmovement@example.com/api/en/movements/testmovement.json?draft_homepage_id=45",
      :body => stub_movement.merge(:join_headline => "Preview headline").to_json

    get :preview, :locale => "en", :draft_homepage_id => 45

    assigns[:movement].join_headline.should eql "Preview headline"
    response.headers['Content-Language'].should eql 'en'
    response.should render_template "home/preview"
  end

  it "should redirect to a locale if none is given" do
    stub_movement_request
    I18n.stub(:available_locales).and_return [:en, :fr]
    {:get => "/foo/bar"}.should route_to(:controller => "home", :action => "redirect", :path => "foo/bar")
  end
end
