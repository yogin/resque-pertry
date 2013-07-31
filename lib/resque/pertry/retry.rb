module Resque
  module Pertry
    module Retry
      extend ActiveSupport::Concern

      included do
        # set a default max number of retry attempts
        set_retry_attempts 1
      end

      module ClassMethods
        
        # Sets a number of seconds to wait before retrying
        def set_retry_delay(delay)
          @retry_delay = Integer(delay)
        end
        
        def retry_delay
          @retry_delay
        end

        # Sets a list of delays (list length will be the # of attempts)
        def set_retry_delays(*delays)
          @retry_delays = Array(delays).map { |delay| Integer(delay) }
        end

        def retry_delays
          @retry_delays
        end

        # Sets the maximum number of times we will retry
        def set_retry_attempts(count)
          @retry_attempts = Integer(count)
        end

        def retry_attempts
          @retry_attempts
        end

        # Sets the maximum time-to-live of the job, after which no attempts will ever be made
        def set_retry_ttl(ttl)
          @retry_ttl = Integer(ttl)
        end

        def retry_ttl
          @retry_ttl
        end

        # Sets a list of exceptions that we want to retry
        # If none are set, we will retry every exceptions
        def set_retry_exceptions(*exceptions)
          @retry_exceptions = Array(exceptions)
        end

        def retry_exceptions
          @retry_exceptions
        end

        # Check if we will retry this job on failure
        # There has to be a constraint on the number of times we will retry a failing job
        # or have a ttl, otherwise we could be retrying job endlessly
        def retryable?
          retry_attempts || retry_delays || retry_ttl
        end

        # Resque around_perform hook
        def around_perform_pertry_00_retry(args = {})
          ResquePertryPersistence.trying_job(self, args)

          yield
        end

        # Resque on_failure hook (job failed)
        def on_failure_pertry_00_retry(exception, args = {})
          return unless retryable?

          ResquePertryPersistence.with_job(self, args) do |job_model|
            job = instance(args)

            unless job.retry!(job_model, exception)
              ResquePertryPersistence.fail_job(self, args)
            end
          end
        end

      end

      # Checks if we can retry
      def retry?(model, exception)
        # check the obvious
        return false unless model
        return false if model.has_completed?

        # job has used up all it's allowed attempts
        return false if max_attempt_reached?(model)

        # job exception is not whitelisted for retries
        return false unless exception_whitelisted?(model, exception)

        # job has expired
        return false if ttl_expired?(model)

        # seems like we should be able to retry this job
        return true
      end

      # Retry the job
      def retry!(model, exception)
        return false unless retry?(model, exception)

        delay = delay_before_retry(model)
        return false unless delay

        if delay > 0
          Resque.enqueue_in(delay, self.class, payload)
        else
          Resque.enqueue(self.class, payload)
        end
      end

      def exception_whitelisted?(model, exception)
        # all exceptions are whitelisted implicitly if we didn't set the exception list
        return true unless self.class.retry_exceptions

        self.class.retry_exceptions.include?(exception.class)
      end

      def ttl_expired?(model)
        # if we didn't set a ttl, it hasn't expired
        return false unless self.class.retry_ttl

        ( model.enqueued_at + self.class.retry_ttl ) < Time.now
      end

      def max_attempt_reached?(model)
        if self.class.retry_attempts && self.class.retry_attempts < model.attempt
          true
        elsif self.class.retry_delays && self.class.retry_delays.size < model.attempt
          true
        else
          false
        end
      end

      def delay_before_retry(model)
        if self.class.retry_delays
          self.class.retry_delays[ model.attempt - 1 ]
        else
          self.class.retry_delay || 0
        end
      end

    end
  end
end
