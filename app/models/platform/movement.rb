class Platform::Movement < Platform::LocalizableResource

  cache!

  def clear_header_navigation_bar
    self.header_navbar = ''
  end
end