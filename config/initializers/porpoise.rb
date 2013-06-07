Rails.application.config.filter_parameters += [:card_number, :card_cvv2, :card_expiration_month, :card_expiration_year]

Rails.application.config.to_prepare do
  Platform.configure
end
