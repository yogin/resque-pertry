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
          @failed_jobs_limit ||= 50
        end

        def run
          setup

          loop do
            purge
            wait
          end
        end

        def setup
          procline("starting")
          register_signal_handlers
        end

        def register_signal_handlers
          trap("TERM") { shutdown }
          trap("INT") { shutdown }
          trap("QUIT") { shutdown }
          trap("USR1") { status }
          trap("USR2") { purge_all }
        end

        def wait
          procline("sleeping")
          sleep(sleep_time)
        end

        def shutdown
          procline("shutting down")
          exit
        end

        def procline(string)
          $0 = "resque-pertry purger: #{string}"
        end

        def status
        end

        def purge
          procline("working")
          purge_resque
          purge_resque_pertry
        end

        def purge_all
        end

        # purge jobs in the failed queue
        def purge_resque
          failed_jobs_limit.times do
            case Resque.redis.name
            when "Redis"
              purge_redis(Resque.redis)
            when "Resque::RedisComposite"
              Resque.redis.mapping.each do |_, redis|
                purge_redis(redis)
              end
            else
              raise NotImplementedError, "Unsupported redis client #{Resque.redis.inspect}"
            end
          end
        end

        def purge_redis(redis)
        end

        # purge resque-pertry persistence table
        def purge_resque_pertry
        end

      end

    end
  end
end
