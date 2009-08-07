require 'rubygems'
require 'active_support'
require 'spec/autorun'
require 'bigdecimal'
require 'bigdecimal/util'
require 'handsoap'

ROOT_PATH = File.expand_path File.join(File.dirname(__FILE__), '..')

$: << File.join(ROOT_PATH, 'app', 'models')
$: << File.join(ROOT_PATH, 'lib')

require 'adempiere_service/base'
require 'adempiere_service/field'
require 'adempiere_service/service'
require 'adempiere_service/payment'


Spec::Runner.configure do |config|

end