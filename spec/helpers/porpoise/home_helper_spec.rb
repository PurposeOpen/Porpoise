require 'spec_helper'

# Specs in this file have access to a helper object that includes
# the HomeHelper. For example:
#
# describe HomeHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       helper.concat_strings("this","that").should == "this that"
#     end
#   end
# end
describe Porpoise::HomeHelper do
  it "should display the list of languages in alphabetical order" do
    stub_movement_request 'pt'

    sorted_languages = helper.sorted_languages Platform::Movement.find("testmovement", :params=>{:locale=>'pt'}).languages

    sorted_languages[0].iso_code.should == "pt"
    sorted_languages[1].iso_code.should == "en"
    sorted_languages[2].iso_code.should == "it"
  end
end

