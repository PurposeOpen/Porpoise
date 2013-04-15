require 'recurly'

module Porpoise::RecurlyConfigurationHelper
	def set_recurly_key(classification)
    case classification
      when '501(c)3'
        classification = '501C3'
      when '501(c)4'
        classification = '501C4'
    end

    Recurly.api_key = ENV["#{classification}_RECURLY_KEY"]
  end

  def recurly_account(classification)
  	case classification
      when '501(c)3'
        classification = '501C3'
      when '501(c)4'
        classification = '501C4'
    end

    ENV["#{classification}_RECURLY_ACCOUNT"]
  end
end