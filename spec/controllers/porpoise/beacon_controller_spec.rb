require 'spec_helper'

describe BeaconController do
  describe "index" do

    it "returns a mime-type of text/gif for all requests" do
      response = get :index
      response.headers["Content-Type"].should == "image/gif"
    end

    it "returns a status code of 200 with no data passed" do
      response = get :index
      response.status.should eql 200
    end

    it "returns a status code of 200 with non-base64 encoded data passed" do
      FakeWeb.register_uri :get, "http://testmovement:testmovement@example.com/api/movements/testmovement/email_tracking/email_opened?t=borked", :code => 400.to_json

      response = get :index, :t => "borked"
      response.status.should eql 200
    end

    it "records an email viewed! user activity event against the specified user" do
      email_tracking_hash = Base64.urlsafe_encode64("userid=25,emailid=7")
      FakeWeb.register_uri :get, "http://testmovement:testmovement@example.com/api/movements/testmovement/email_tracking/email_opened?t=#{email_tracking_hash}", :body => { :content => "all good" }.to_json

      response = get :index, :t => email_tracking_hash

      response.status.should eql 200
    end
  end
end
