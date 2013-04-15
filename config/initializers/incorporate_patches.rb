Pathname.glob(File.join(File.dirname(__FILE__), "../../lib/patches", "**/*.rb")).each do |patch|
  require patch
end
