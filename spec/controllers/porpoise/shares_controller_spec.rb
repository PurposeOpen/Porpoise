require 'spec_helper'

describe SharesController do

  before do
    FakeWeb.register_uri :post, "http://testmovement:testmovement@example.com/api/movements/testmovement/shares", :status => [200, "OK"]
  end

  it 'should post to the platform to create a share' do
    post :create, :user_id => 1, :page_id => 2, :share_type => 'facebook'
    response.should be_success
  end

end