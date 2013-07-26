module Resque
  module Pertry
    module Retry
      extend ActiveSupport::Concern

      module ClassMethods
        
        # Sets a number of seconds to wait before retrying
        def retry_delay(delay)
        end

        # Sets a list of delays (list length will be the # of attempts)
        def retry_delays(delays)
        end

        # Sets the maximum number of times we will retry
        def retry_attempts(count)
        end

        # Sets a list of exceptions that we want to retry
        # If none are set, we will retry every exceptions
        def retry_exceptions(exceptions)
        end

        # Check if we will retry this job on failure
        def retryable?
          true
        end

        # Resque before_enqueue hook
        def before_enqueue_pertry_retry(args = {})
          return unless retryable?

          args[Resque::Pertry::Job::JOB_HASH] ||= {}
          args[Resque::Pertry::Job::JOB_HASH][:attempt] ||= 0
          args[Resque::Pertry::Job::JOB_HASH][:attempt] += 1

          # continue with enqueue
          true
        end

      end

      # Checks if we can retry
      def retry?
      end

      # Retry the job
      def retry!
      end

    end
  end
end
