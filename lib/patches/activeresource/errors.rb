# Source: https://github.com/rails/activeresource/blob/a05a725ee75f3c18df4a57a1cc27448ba83880f0/lib/active_resource/validations.rb
# Issue: https://github.com/rails/rails/pull/3046
#TODO Remove this patch once ActiveResource has been upgraded to a version that incorporates this change.

require 'active_resource/base'

ActiveResource::Errors.class_eval do
  # Grabs errors from an array of messages (like ActiveRecord::Validations).
  # The second parameter directs the errors cache to be cleared (default)
  # or not (by passing true).
  def from_array(messages, save_cache = false)
    clear unless save_cache
    humanized_attributes = Hash[@base.attributes.keys.map { |attr_name| [attr_name.humanize, attr_name] }]
    messages.each do |message|
      attr_message = humanized_attributes.keys.detect do |attr_name|
        if message[0, attr_name.size + 1] == "#{attr_name} "
          add humanized_attributes[attr_name], message[(attr_name.size + 1)..-1]
        end
      end

      self[:base] << message if attr_message.nil?
    end
  end

  # Grabs errors from a hash of attribute => array of errors elements
  # The second parameter directs the errors cache to be cleared (default)
  # or not (by passing true)
  #
  # Unrecognized attribute names will be humanized and added to the record's
  # base errors.
  def from_hash(messages, save_cache = false)
    clear unless save_cache

    messages.each do |(key,errors)|
      errors.each do |error|
        if @base.attributes.keys.include?(key)
          add key, error
        elsif key == 'base'
          self[:base] << error
        else
          # reporting an error on an attribute not in attributes
          # format and add them to base
          self[:base] << "#{key.humanize} #{error}"
        end
      end
    end
  end

  # Grabs errors from a json response.
  def from_json(json, save_cache = false)
    decoded = ActiveSupport::JSON.decode(json) || {} rescue {}
    if decoded.kind_of?(Hash) && (decoded.has_key?('errors') || decoded.empty?)
      errors = decoded['errors'] || {}
      if errors.kind_of?(Array)
        # 3.2.1-style with array of strings
        ActiveSupport::Deprecation.warn('Returning errors as an array of strings is deprecated.')
        from_array errors, save_cache
      else
        # 3.2.2+ style
        from_hash errors, save_cache
      end
    else
      # <3.2-style respond_with - lacks 'errors' key
      ActiveSupport::Deprecation.warn('Returning errors as a hash without a root "errors" key is deprecated.')
      from_hash decoded, save_cache
    end
  end

  # Grabs errors from an XML response.
  def from_xml(xml, save_cache = false)
    array = Array.wrap(Hash.from_xml(xml)['errors']['error']) rescue []
    from_array array, save_cache
  end
end