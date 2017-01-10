# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.ruby_opts = "-w"
end

RuboCop::RakeTask.new(:rubocop)

task default: [:spec, :rubocop]
