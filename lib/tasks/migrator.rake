namespace :migrator do
  desc 'Add webservice lines into the adempiere database.'
  task :migrate do
    require 'activesupport'
    
    (Dir[File.join(File.dirname(__FILE__), '..', '**', '*.rb')] +
     Dir[File.join(File.dirname(__FILE__), '..', '..', 'app', 'models', '**', '*.rb')]).
    each { |f| require f }
    
    Object.subclasses_of(AdempiereService::Base).each do |s|
      m = AdempiereService::Migrator.new(s)
      m.migrate!
    end
  end
end