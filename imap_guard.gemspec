# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "imap_guard"
  spec.version       = "2.0.0"
  spec.authors       = ["Cédric Félizard"]
  spec.email         = ["cedric@felizard.fr"]
  spec.description   = "A guard for your IMAP server"
  spec.summary       = spec.description
  spec.homepage      = "https://github.com/infertux/imap_guard"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/) # rubocop:disable Style/SpecialGlobalVars
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.0.4"

  spec.add_dependency "mail", ">= 2.7.1"
  spec.add_dependency "net-imap"
  spec.add_dependency "net-smtp" # TODO: remove when https://github.com/mikel/mail/issues/1482 resolved
  spec.add_dependency "term-ansicolor", ">= 1.2.2"

  spec.add_development_dependency "bundler", ">= 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "redcarpet" # for yardoc
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-rake"
  spec.add_development_dependency "rubocop-rspec"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "yard"
  spec.metadata["rubygems_mfa_required"] = "true"
end
