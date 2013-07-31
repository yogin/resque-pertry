require 'resque/tasks'
require 'resque_scheduler/tasks'

namespace :resque do
  task :setup

  namespace :pertry do
    desc "Start Resque Pertry database and failed queue purger"
    task :purger => :pertry_setup do
      File.open(ENV['PIDFILE'], 'w') { |f| f << Process.pid.to_s } if ENV['PIDFILE']

      Resque::Pertry::Purger.sleep_time = Integer(ENV['PURGER_SLEEP']) if ENV['PURGER_SLEEP']
      Resque::Pertry::Purger.failed_jobs_limit = Integer(ENV['PURGER_LIMIT']) if ENV['PURGER_LIMIT']
      Resque::Pertry::Purger.verbose = true if ENV['VERBOSE']
      Resque::Pertry::Purger.run
    end

    task :pertry_setup do
      Rake::Task['resque:setup'].invoke
    end
  end
end
