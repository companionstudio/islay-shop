# encoding: UTF-8
require 'rubygems'
require 'bundler/setup'
require 'yard'
require 'rspec/core/rake_task'

APP_RAKEFILE = File.expand_path("../spec/dummy/Rakefile", __FILE__)
load 'rails/tasks/engine.rake'

RSpec::Core::RakeTask.new(:spec => 'app:db:test:prepare')
YARD::Rake::YardocTask.new {|t| t.files = ['{app,lib}/**/*.rb']}
Bundler::GemHelper.install_tasks

task :default => :spec
