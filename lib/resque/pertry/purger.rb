module Resque
  module Pertry
    class Purger

      class << self

        attr_accessor :verbose

        # sleep time between purges
        attr_writer :sleep_time

        # sets the number of failed jobs to purge per run
        attr_writer :failed_jobs_limit

        def sleep_time
          @sleep_time ||= 5.seconds #10.minutes
        end

        def failed_jobs_limit
          @failed_jobs_limit ||= 10
        end

        def stats
          @stats ||= {}
        end

        # main loop
        def run
          setup

          loop do
            purge
            wait
          end
        end

        # run a purge cycle
        def purge
          procline("working")
          add_stat(:loops, 1)

          purge_resque
          purge_persistence
        end

        # display status of failed queues and persistence table
        def status
          show_config
          show_info
        end

        # allows an app to set a hook to deal with the failed redis job
        def after_redis_purge(&block)
          @after_redis_purge = block
        end

        # allows an app to set a hook to deal with the failed persistence table job
        def after_persistence_purge(&block)
          @after_persistence_purge = block
        end

        private

        # purger setup and init
        def setup
          stats[:pid] = Process.pid
          stats[:started] = Time.now
          stats[:loops] = 0

          procline("starting")
          status
          register_signal_handlers
        end

        # intercept signals
        def register_signal_handlers
          trap("TERM") { shutdown }
          trap("INT")  { shutdown }
          trap("QUIT") { shutdown }
          trap("USR1") { status }
        end

        def show_config
          log("Configuration:")
          [ :sleep_time, :failed_jobs_limit ].each do |v|
            log("\tconfig #{v} = #{send(v)}")
          end
        end

        def show_info
          with_redis do |redis|
            set_stat("failed queue length on #{redis.id}", redis.llen(:failed))
          end
          
          log!("Status:")
          stats.each do |key, value|
            log!("\t#{key} : #{value}")
          end
        end

        # just sleep for a while
        def wait
          procline("sleeping for #{sleep_time} seconds")
          sleep(sleep_time)
        end

        # shutdown the process
        def shutdown
          procline("shutting down")
          exit
        end

        # update process line
        def procline(string)
          log(string)
          $0 = "resque-pertry purger: #{string}"
        end

        # purge jobs in the failed queue
        def purge_resque
          with_redis do |redis|
            purge_redis(redis)
          end
       end

        def with_redis(&block)
          return {} unless block_given?

          # testing the redis class name so we don't have to require resque_redis_composite
          case Resque.redis.redis.class.name
          when "Redis"
            { redis.id => block.call(Resque.redis) }
          when "Resque::RedisComposite"
            Resque.redis.mapping.reduce({}) do |results, (queue, redis)|
              results[redis.id] = block.call(redis)
              results
            end
          else
            raise NotImplementedError, "Unsupported redis client #{Resque.redis.inspect}"
          end
        end

        # purge resque's failed queue on a redis client
        def purge_redis(redis)
          failed_jobs = redis.lrange(:failed, 0, failed_jobs_limit - 1)
          return 0 if failed_jobs.empty?

          log("purging #{failed_jobs.size} failed jobs from #{redis.id}")
          #redis.ltrim(:failed, failed_jobs.size, -1)

          failed_jobs.each do |failed_job|
            run_after_redis_purge(failed_job)
          end if @after_redis_purge

          add_stat("purged from #{redis.id}", failed_jobs.size)
        end

        # purge resque-pertry persistence table
        def purge_persistence
          failed_jobs = ResquePertryPersistence.finnished.limit(failed_jobs_limit)
          return 0 if failed_jobs.empty?

          log("purging #{failed_jobs.size} completed or failed jobs from database")

          failed_jobs.each do |failed_job|
            #ResquePertryPersistence.destroy(failed_job.id)
            run_after_persistence_purge(failed_job)
          end if @after_persistence_purge

          add_stat("purged from database", failed_jobs.size)
        end

        # run hook after_redis_purge
        def run_after_redis_purge(job)
          return unless @after_redis_purge
          @after_redis_purge.call(job)
        rescue => e
          log!("exception #{e.inspect} while running hook after_redis_purge on job #{job.inspect}")
        end

        # run hook after_persistence_purge
        def run_after_persistence_purge(job)
          return unless @after_persistence_purge
          @after_persistence_purge.call(job)
        rescue => e
          log!("exception #{e.inspect} while running hook after_persistence_purge on job #{job.inspect}")
        end

        # only print if verbose is turned on
        def log(string)
          log!(string) if verbose
        end

        # always print this string
        def log!(string)
          $stdout.puts "#{Time.now.strftime("%Y-%m-%d %H:%M:%S.%L")} - #{string}"
        end

        def add_stat(stat, value)
          stats[stat] ||= 0
          stats[stat] += value
          value
        end

        def set_stat(stat, value)
          stats[stat] = value
        end

      end

    end
  end
end
