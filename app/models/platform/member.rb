class Platform::Member < Platform::Base
  self.element_name = 'member'

  schema do
    string 'email', 'first_name', 'last_name', 'country_iso', 'comment', 'postcode', 'mobile_number', 'home_number', 'suburb', 'street_address'
    integer 'movement_id'
  end
end