require 'rubygems'
require 'active_support'
require 'spec/autorun'
require 'bigdecimal'
require 'bigdecimal/util'
require 'handsoap'

ROOT_PATH = File.expand_path File.join(File.dirname(__FILE__), '..')

(Dir[File.join(ROOT_PATH, 'lib', '**',           '*.rb')] +
 Dir[File.join(ROOT_PATH, 'app', 'models', '**', '*.rb')]).each do |file|
  require file
end

Spec::Runner.configure do |config|

end