require 'spec_helper'

describe 'preview routes' do
  it 'should route to home#preview' do
    {:get => '/en/preview'}.should route_to(:controller => 'home', :action => 'preview', :locale => 'en')
  end
end
