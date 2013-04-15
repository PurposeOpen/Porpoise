class Platform::Movement < Platform::Base

  cache!

  def clear_header_navigation_bar
    self.header_navbar = ''
  end
end