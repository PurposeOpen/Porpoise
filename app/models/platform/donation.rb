class Platform::Donation < Platform::Base
	self.element_name = 'donation'

	def self.find_by_subscription_id(subscription_id)
		# The find method using the :first scope requires the web service to return a collection.
		# To avoid changing the Platform API to fit this requirement, we use the :one scope which requires specifying the :from option
		find(:one, :from => find_by_subscription_id_path, :params => {:subscription_id => subscription_id})
	end

	private
	def self.find_by_subscription_id_path
		base_uri = self.site.to_s
		if !base_uri.match(/\/$/)
			base_uri << '/'
		end
		URI.join(base_uri, 'donations').to_s
	end
end