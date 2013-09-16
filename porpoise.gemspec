# -*- encoding: utf-8 -*-
require File.expand_path('../lib/porpoise/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "porpoise"
  gem.version       = Porpoise::VERSION
  
  gem.authors       = ["Purpose"]
  gem.email         = ["technology@purpose.com"]
  gem.description   = "Purpose Platform client library."
  gem.summary       = "Purpose Platform client library."
  gem.homepage      = "https://github.com/PurposeOpen/Porpoise"

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_dependency "activeresource", "~> 4.0.0"
  gem.add_dependency "app_constants"
  gem.add_dependency "rack-timeout"
  gem.add_dependency "money"
  gem.add_dependency "activemerchant", "~> 1.29.3"
  gem.add_dependency "recurly"
  gem.add_development_dependency "rspec", ">= 2.0"
  gem.add_development_dependency "fakeweb"
  gem.add_development_dependency "stickler", "~> 2.2.4"
end
