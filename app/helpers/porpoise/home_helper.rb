module Porpoise::HomeHelper
  def sorted_languages(languages)
    default_language, rest = languages.partition { |l| l.is_default }
    default_language + rest.sort_by(&:iso_code)
  end
end
