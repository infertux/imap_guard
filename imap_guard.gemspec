# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "imap_guard"
  spec.version       = "1.1.0"
  spec.authors       = ["Cédric Félizard"]
  spec.email         = ["cedric@felizard.fr"]
  spec.description   = "A guard for your IMAP server"
  spec.summary       = spec.description
  spec.homepage      = "https://github.com/infertux/imap_guard"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "mail", ">= 2.5.3"
  spec.add_dependency "term-ansicolor", ">= 1.2.2"

  spec.add_development_dependency "bundler", ">= 1.3"
  spec.add_development_dependency "cane"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "redcarpet" # for yardoc
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "yard"
end
