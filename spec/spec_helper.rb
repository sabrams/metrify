$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'metrify'
if Rails::VERSION::MAJOR == 3
  require 'rspec'
  require 'rspec/autorun'

else
  require 'spec'
  require 'spec/autorun'
end  

require 'rubygems'
require 'active_record'

ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + '/debug.log')
ActiveRecord::Base.configurations = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.establish_connection(ENV['DB'] || 'mysql')

load(File.dirname(__FILE__) + '/schema.rb')

Spec::Runner.configure do |config|
  
end
