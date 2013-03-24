require 'simplecov'
SimpleCov.start do
  minimum_coverage 90
  add_group "Sources", "lib"
  add_group "Tests", "spec"
end

require 'imap_guard'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |file| require file }

