require 'rake'
require 'spec/rake/spectask'

Dir[File.join(File.dirname(__FILE__), 'lib', 'tasks', '*.rake')].each { |f| load f }

desc "Specs"
namespace :spec do
  desc "Unit specs for the libs."
  Spec::Rake::SpecTask.new('libs') do |t|
    t.spec_files = FileList['spec/lib/*.rb']
  end
  
  desc "Run all specs"
  task :all => :libs
end

desc "Run all specs"
task :default => 'spec:all'