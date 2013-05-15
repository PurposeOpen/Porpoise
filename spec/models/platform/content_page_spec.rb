require "spec_helper"

describe Platform::ContentPage do
  it "should return the preview element path" do
    Platform::ContentPage.preview_element_path(1, :locale => :en).should == "en/movements/#{Platform.movement_id}/content_pages/1/preview.json"
  end
end