# frozen_string_literal: true

begin
  require 'faculty/rake'
rescue LoadError
  system 'gem install --source https://gem.fury.io/universityofyork/ uoy-faculty-rake'
  Gem.clear_paths
  require 'faculty/rake'
end

# 1.7.4 needed for db_reset in init task
unless Gem.loaded_specs['uoy-faculty-rake'].version >= Gem::Version.new('1.7.4')
  system 'gem update --source https://gem.fury.io/universityofyork/ uoy-faculty-rake'
  # We cannot easily reload the gem at this point
  puts "\e[1mFaculty rake helpers gem updated; please run rake again\e[22m"
  exit
end

Faculty::Rake::BaseUpdate.new 'git@github.com:university-of-york/faculty-dev-sinatra-base.git', 'base-update'
Faculty::Rake::Deploy.new
Faculty::Rake::DockerTasks.new
Faculty::Rake::SinatraRename.new

task default: :up

desc 'Initialise app for local development'
task init: [:down, :db_reset, :build, 'bundle:install', :up]
