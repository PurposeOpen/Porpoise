class Platform::LocalizableResource < Platform::Base
	# Add value for the locale parameter if it's not already set
	def self.find(*arguments)
		arguments << {} if arguments.length < 2

		options = arguments.slice(1)

		if !options[:params] || !options[:params][:locale]
			options[:params] = (options[:params] || {}).merge({ :locale => I18n.locale })
		end

		super(*arguments)
	end
end