class Platform::Donation < Platform::Base
	self.element_name = 'donation'

	def self.find_by_subscription_id(subscription_id)
		# The find method using the :first scope requires the web service to return a collection.
		# To avoid changing the Platform API to fit this requirement, we use the :one scope which requires specifying the :from option
		find(:one, :from => "#{self.site}/donations", :params => {:subscription_id => subscription_id})
	end
end