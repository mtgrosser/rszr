require "bundler/gem_tasks"

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)

  task :default => :spec
rescue LoadError
  # no rspec available
end

require 'rake/extensiontask'

Rake::ExtensionTask.new('rszr') do |ext|
  ext.lib_dir = 'lib/rszr'
end
