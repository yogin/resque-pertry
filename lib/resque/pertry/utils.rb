module Resque
  module Pertry
    module Utils

      # Retry Jobs identified by audit_ids
      # Jobs still need to meet retry requirements
      def retry_jobs(audit_ids)
        with_persistent_jobs(audit_ids) do |job, model|
          job.retry!(model)
        end
      end

      # Fail all jobs by audit_id
      def fail_jobs(audit_ids)
        with_persistent_jobs(audit_ids) do |job, model|
          job.fail_job!
        end
      end

      # Complete all jobs by audit_id
      def complete_jobs(audit_ids)
        with_persistent_jobs(audit_ids) do |job, model|
          job.complete_job!
        end
      end

      # Allow to work on jobs
      def with_persistent_jobs(audit_ids, &block)
        Resque::Pertry::ResquePertryPersistence.where(:audit_id => Array(audit_ids)).each do |model|
          job = model.resque_job
          block.call(job, model) if block_given?
        end
      end

    end
  end
end

Resque.extend Resque::Pertry::Utils
