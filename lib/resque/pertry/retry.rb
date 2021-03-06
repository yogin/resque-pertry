module Resque
  module Pertry
    module Retry
      extend ActiveSupport::Concern

      included do
        class_attribute :_retry_delays
        class_attribute :_retry_delay
        class_attribute :_retry_attempts
        class_attribute :_retry_ttl
        class_attribute :_retry_exceptions

        # set a default max number of retry attempts
        set_retry_attempts 1

        # set job to expire in 1 week (we need a default so we can purge the database)
        set_retry_ttl 1.week
      end

      module ClassMethods
        
        # Sets a number of seconds to wait before retrying
        def set_retry_delay(delay)
          self._retry_delays = nil
          self._retry_delay = delay == :clear ? nil : Integer(delay)
        end
        
        def retry_delay
          self._retry_delay
        end

        # Sets a list of delays (list length will be the # of attempts)
        def set_retry_delays(*delays)
          set_retry_attempts :clear
          set_retry_delay :clear
          self._retry_delays = Array(delays).map { |delay| Integer(delay) }
        end

        def retry_delays
          self._retry_delays
        end

        # Sets the maximum number of times we will retry
        def set_retry_attempts(count)
          self._retry_delays = nil
          self._retry_attempts = count == :clear ? nil : Integer(count)
        end

        def retry_attempts
          self._retry_attempts
        end

        # Sets the maximum time-to-live of the job, after which no attempts will ever be made
        def set_retry_ttl(ttl)
          self._retry_ttl = ttl == :clear ? nil : Integer(ttl)
        end

        def retry_ttl
          self._retry_ttl
        end

        # Sets a list of exceptions that we want to retry
        # If none are set, we will retry every exceptions
        def set_retry_exceptions(*exceptions)
          self._retry_exceptions = Array(exceptions)
        end

        def retry_exceptions
          self._retry_exceptions
        end

        # Quickly reset all retry properties
        # Useful if you have a base job class
        def reset_retry_properties
          self._retry_delays = nil
          self._retry_attempts = nil
          self._retry_delays = nil
          self._retry_ttl = nil
          self._retry_exceptions = nil
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
      def retry?(model, exception = nil)
        # check the obvious
        return false unless model
        return false if model.finnished?

        # job has used up all it's allowed attempts
        return false if max_attempt_reached?(model)

        # job exception is not whitelisted for retries
        return false unless exception_whitelisted?(model, exception)

        # seems like we should be able to retry this job
        return true
      end

      # Retry the job
      def retry!(model, exception = nil)
        return false unless retry?(model, exception)

        delay = delay_before_retry(model)
        return false unless delay

        Resque.enqueue_in(delay, self.class, payload)
      end

      def exception_whitelisted?(model, exception)
        # all exceptions are whitelisted implicitly if we didn't set the exception list
        return true unless self.class.retry_exceptions

        self.class.retry_exceptions.include?(exception.class)
      end

      def ttl_expired?(model)
        # if we didn't set a ttl, it hasn't expired
        return false unless self.class.retry_ttl

        model.expired?
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
