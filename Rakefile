require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    root_files = FileList["README.rdoc", "MIT-LICENSE", "CHANGELOG.rdoc"]
    gem.name = "metrify"
    gem.summary = %Q{Framework to aggregate and display data over time}
    gem.description = %Q{Framework to aggregate and display data over time. Assumes highcharts installation.}
    gem.email = "abrams.stephen@gmail.com"
    gem.homepage = "http://github.com/sabrams/metrify"
    gem.authors = ["Stephen Abrams"]
    gem.files =  root_files + FileList["{app,lib,spec}/**/*"]
    gem.add_development_dependency "rspec", ">= 2.0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

version = `rails --version`.split[1].split('.').first.to_i

if version == 2
  require 'spec/rake/spectask'
  Spec::Rake::SpecTask.new(:spec) do |spec|
    spec.libs << 'lib' << 'spec'
    spec.spec_files = FileList['spec/**/*_spec.rb']
  end

  Spec::Rake::SpecTask.new(:rcov) do |spec|
    spec.libs << 'lib' << 'spec'
    spec.pattern = 'spec/**/*_spec.rb'
    spec.rcov = true
  end
elsif version == 3
  require 'rspec/core'
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec) do |spec|
    spec.pattern = FileList['spec/**/*_spec.rb']
  end

  RSpec::Core::RakeTask.new(:rcov) do |spec|
    spec.pattern = 'spec/**/*_spec.rb'
    spec.rcov = true
  end
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "metrify #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
