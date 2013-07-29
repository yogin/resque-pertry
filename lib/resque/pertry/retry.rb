module Resque
  module Pertry
    module Retry
      extend ActiveSupport::Concern

      module ClassMethods
        
        # Sets a number of seconds to wait before retrying
        def retry_delay(delay)
          @retry_delay = Integer(delay)
        end

        # Sets a list of delays (list length will be the # of attempts)
        def retry_delays(delays)
          raise ArgumentError, "Expecting an array of delays (seconds), but we got #{delays.inspect}" unless Array === delays
          @retry_delays = delays.map { |delay| Integer(delay) }
        end

        # Sets the maximum number of times we will retry
        def retry_attempts(count)
          @retry_attemps = Integer(count)
        end

        # Sets the maximum time-to-live of the job, after which no attempts will ever be made
        def retry_ttl(ttl)
          @retry_ttl = Integer(ttl)
        end

        # Sets a list of exceptions that we want to retry
        # If none are set, we will retry every exceptions
        def retry_exceptions(exceptions)
          raise ArgumentError, "Expecting an array of exceptions, but we got #{exceptions.inspect}" unless Array === exceptions
          @retry_exceptions = exceptions
        end

        # Check if we will retry this job on failure
        def retryable?
          @retry_attempts || @retry_delays
        end

        # Resque around_perform hook
        def around_perform_pertry_00_retry(args = {})
          ResquePertryPersistence.trying_job(self, args)

          yield
        end

        # Resque on_failure hook (job failed)
        def on_failure_pertry_00_retry(exception, args = {})
        end

      end

      # Checks if we can retry
      def retry?
        # TODO
      end

      # Retry the job
      def retry!
        # TODO
      end

    end
  end
end
