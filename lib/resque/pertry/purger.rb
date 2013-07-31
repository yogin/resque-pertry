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
          #purge_resque
          purge_persistence
        end

        # purge all backends from all failed jobs
        def purge_all
        end

        # display status of failed queues and persistence table
        def status
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
          procline("starting")
          register_signal_handlers
        end

        # intercept signals
        def register_signal_handlers
          trap("TERM") { shutdown }
          trap("INT") { shutdown }
          trap("QUIT") { shutdown }
          trap("USR1") { status }
          trap("USR2") { purge_all }
        end

        # just sleep for a while
        def wait
          procline("sleeping")
          sleep(sleep_time)
        end

        # shutdown the process
        def shutdown
          procline("shutting down")
          exit
        end

        # update process line
        def procline(string)
          $0 = "resque-pertry purger: #{string}"
        end

        # purge jobs in the failed queue
        def purge_resque
          # testing the redis class name so we don't have to require resque_redis_composite
          case Resque.redis.redis.class.name
          when "Redis"
            purge_redis(Resque.redis)
          when "Resque::RedisComposite"
            Resque.redis.mapping.reduce(0) do |total, (queue, redis)|
              total += purge_redis(redis)
            end
          else
            raise NotImplementedError, "Unsupported redis client #{Resque.redis.inspect}"
          end
        end

        # purge resque's failed queue on a redis client
        def purge_redis(redis)
          failed_jobs = redis.lrange(:failed, 0, failed_jobs_limit - 1)
          return 0 if failed_jobs.empty?

          # trim the queue
          redis.ltrim(:failed, failed_jobs.size, -1)

          failed_jobs.each do |failed_job|
            run_after_redis_purge(failed_job)
          end if @after_redis_purge

          failed_jobs.size
        end

        # purge resque-pertry persistence table
        def purge_persistence
          failed_jobs = ResquePertryPersistence.failed.limit(failed_jobs_limit)
          return 0 if failed_jobs.empty?

          failed_jobs.each do |failed_job|
            ResquePertryPersistence.destroy(failed_job.id)
            run_after_persistence_purge(failed_job)
          end if @after_persistence_purge

          failed_jobs.size
        end

        # run hook
        def run_after_redis_purge(job)
          return unless @after_redis_purge
          @after_redis_purge.call(job)
        end

        # run hook
        def run_after_persistence_purge(job)
          return unless @after_persistence_purge
          @after_persistence_purge.call(job)
        end

      end

    end
  end
end
