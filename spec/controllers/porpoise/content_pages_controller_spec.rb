require 'spec_helper'

describe ContentPagesController do
  describe "#show" do
    it "should redirect to action page if the page received is of type 'ActionPage'" do
      FakeWeb.register_uri :get, "http://testmovement:testmovement@example.com/api/movements/testmovement.json",
                           :body => { :title => "Movement", :content => "Movement content with email tracking hash and action page",
                                      :languages => [], :recommended_languages_to_display => [] }.to_json
      FakeWeb.register_uri :get, "http://testmovement:testmovement@example.com/api/movements/testmovement/content_pages/take-the-first-step-endorse-the-five-freedoms.json",
                           :body => { :title => "Save the Italian-speaking Turtles!", :type => 'ActionPage', :content => "Save them!"}.to_json

      get :show, { :content_page => 'take-the-first-step-endorse-the-five-freedoms', :locale => 'it'}
      response.should redirect_to(action_path('take-the-first-step-endorse-the-five-freedoms', :locale => 'it'))
    end
  end

  describe "GET preview" do
    it "should return preview for action page which are unpublished" do
      stub_movement_request
      FakeWeb.register_uri :get, "http://testmovement:testmovement@example.com/api/movements/testmovement/content_pages/10.json", :body => { :title => "Save the Italian-speaking Turtles!", :content => "Content with email!"}.to_json
      FakeWeb.register_uri :get, "http://testmovement:testmovement@example.com/api/movements/testmovement/content_pages/10/preview.json",
                           :body => {:title => "Save the Italian-speaking Turtles!", :content => "Content with email!"}.to_json
      get :preview, {:content_page => 10, :locale => 'it'}

      Platform::ContentPage.headers['Accept-Language'].should eql 'it'
      assigns[:page].content.should eql "Content with email!"
      assigns[:page].title.should eql "Save the Italian-speaking Turtles!"
      assigns[:member].should be_kind_of(Platform::Member)
    end
  end
end

