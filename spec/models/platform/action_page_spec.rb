require "spec_helper"

describe Platform::ActionPage do
  it "should return the preview element path" do
    Platform::ActionPage.preview_element_path(1).should == "/api/movements/#{Platform.movement_id}/action_pages/1/preview.json"
  end
end