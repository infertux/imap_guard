# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  minimum_coverage 95
  add_group "Sources", "lib"
  add_group "Tests", "spec"
end

require "imap_guard"

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |file| require file }
