require 'resque/tasks'
require 'resque_scheduler/tasks'

namespace :resque do
  task :setup

  namespace :pertry do
    desc "Start Resque Pertry database and failed queue purger"
    task :purger => :pertry_setup do
      $stdout.puts "done!"
    end

    task :pertry_setup do
      Rake::Task['resque:setup'].invoke
    end
  end
end
