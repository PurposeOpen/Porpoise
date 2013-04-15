module Porpoise
  MAJOR = 1
  MINOR = 0
  REVISION = ENV['BUILD_NUMBER'] || 'dev'

  VERSION = "#{MAJOR}.#{MINOR}.#{REVISION}"
end
