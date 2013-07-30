module Resque
  module Pertry
    class ResquePertryPersistence < ActiveRecord::Base

      self.table_name = "resque_pertry_persistence"

      class << self

        def create_job_if_needed(klass, args)
          with_job(klass, args) do |job|
            # we already have a job for this, we don't want another
            return if job

            # creating a new job
            new(  :audit_id => field_from_args('audit_id', args),
                  :job => klass.to_s,
                  :arguments => args.to_json, 
                  :attempt => 0,
                  :enqueued_at => field_from_args('queue_time', args)).save!
          end
        end


        def finnish_job(klass, args)
          with_job(klass, args) do |job|
            job.update_attribute(:completed_at, Time.now)
          end
        end

        def trying_job(klass, args)
          with_job(klass, args) do |job|
            job.update_attributes(  :last_tried_at => Time.now,
                                    :attempt => job.attempt + 1)
          end
        end

        def fail_job(klass, args)
          with_job(klass, args) do |job|
            job.update_attribute(:failed_at, Time.now)
          end
        end

        def with_job(klass, args, &block)
          audit_id = field_from_args('audit_id', args)
          return unless audit_id
          
          job = find_by_audit_id(audit_id)
          block.call(job) if block_given?
        end

        private

        def field_from_args(field, args)
          pertry_hash = args[Resque::Pertry::Job::JOB_HASH] || args[Resque::Pertry::Job::JOB_HASH.to_s] || {}
          pertry_hash[field]
        end

      end

      def has_completed?
        completed_at
      end

    end
  end
end