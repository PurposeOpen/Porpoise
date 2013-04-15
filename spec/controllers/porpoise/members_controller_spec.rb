require 'spec_helper'

describe MembersController do

  before do
    stub_create_member
    stub_movement_request
  end

  describe "POST 'create'" do

    context 'welcome page exists' do

      context 'new member' do

        it 'should redirect to path the platform specifies as the next page id' do
          post 'create', :locale => "en", :member_info => {:email => "lemmy@kilmister.com", 'next_page_identifier' => 'chocolate'}
          response.should redirect_to action_path(I18n.locale, 'chocolate', :email => "lemmy@kilmister.com")
        end

        it 'redirects to the "join" page when there are validation errors on the Member' do
          FakeWeb.register_uri(:post, %r[http://testmovement:testmovement@example.com/api/movements/testmovement/members], :status => 422, :body => '')
          post 'create', :locale => "en", :member_info => { :email => '', 'next_page_identifier' => 'chocolate' }
          response.should redirect_to action_path(I18n.locale, 'join')
        end

        it 'should redirect to the root path when the platform does not specify a next page id' do
          post 'create', :locale => "en", :member_info => {:email => "lemmy@kilmister.com"}
          response.should redirect_to root_path(:locale => I18n.locale)
        end

        it "persists the new member object to the platform" do
          member = mock("member", :email => "lemmy@kilmister.com", :attributes => {'next_page_identifier' => ''})
          member.should_receive(:save!).and_return true
          Platform::Member.stub(:new).and_return member
          post 'create', :locale => "en", :member_info => {:email => "lemmy@kilmister.com"}
        end

        it "persists the new member object to the platform and returns the member id, and puts the member id in the session" do
          member = mock("member", :email => "lemmy@kilmister.com", :attributes => {'next_page_identifier' => '', 'member_id' => '12'})
          member.should_receive(:save!).and_return true
          Platform::Member.stub(:new).and_return member
          post 'create', :locale => "en", :member_info => {:email => "lemmy@kilmister.com"}

          assigns[:member].attributes['member_id'].should == '12'
          session[:member_id].should == 12
        end

        it "does not set member id session variable if it is blank" do
          member = mock("member", :email => "lemmy@kilmister.com", :attributes => {'next_page_identifier' => '', 'member_id' => ''})
          member.should_receive(:save!).and_return true
          Platform::Member.stub(:new).and_return member
          post 'create', :locale => "en", :member_info => {:email => "lemmy@kilmister.com"}

          assigns[:member].attributes['member_id'].should == ''
          session[:member_id].should be_nil
        end

      end

    end

  end

end
