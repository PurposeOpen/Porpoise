class Platform::Donation < Platform::Base
	self.element_name = 'donation'

	def self.find_by_subscription_id(subscription_id)
		# The find method using the :first scope requires the web service to return a collection.
		# To avoid changing the Platform API to fit this requirement, we use the :one scope which requires specifying the :from option
		find(:one, :from => find_by_subscription_id_path, :params => {:subscription_id => subscription_id})
	end

	private
	def self.find_by_subscription_id_path
		"#{prefix}#{collection_name}.#{format.extension}"
	end
end