require 'spec_helper'

describe ErrorsController do
  before do
    stub_movement_request('en')
  end
  it "page_not_found should redirect to page_not_found url" do
    get :page_not_found
    response.should redirect_to(AppConstants.page_not_found_url)
  end

  it "went_wrong should redirect to error url" do
    get :went_wrong
    response.should redirect_to(AppConstants.error_url)
  end

  it "went_wrong should redirect to homepage error url" do
    ErrorsController.any_instance.stub(:homepage?).and_return(true)
    get :went_wrong
    response.should redirect_to(AppConstants.homepage_error_url)
  end
end
