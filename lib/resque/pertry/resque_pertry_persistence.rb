module Resque
  module Pertry
    class ResquePertryPersistence < ActiveRecord::Base

      self.table_name = "resque_pertry_persistence"

      default_scope -> { order(:updated_at) }
      scope :completed, -> { where("completed_at IS NOT NULL") }
      scope :failed,    -> { where("failed_at IS NOT NULL") }
      scope :finnished, -> { where("completed_at IS NOT NULL OR failed_at IS NOT NULL") }
      scope :ongoing,   -> { where(:completed_at => nil, :failed_at => nil) }
      scope :expired,   -> { where("expires_at < ?", Time.now) }
      scope :finnished_or_expired, -> { where("completed_at IS NOT NULL OR failed_at IS NOT NULL OR expires_at < ?", Time.now) }

      class << self

        def create_job_if_needed(klass, args)
          with_job(klass, args) do |job|
            # we already have a job for this, we don't want another
            return if job

            # creating a new job
            params = {
              :audit_id => field_from_args('audit_id', args),
              :job => klass.to_s,
              :arguments => Resque.encode(args), 
              :attempt => 0,
              :enqueued_at => field_from_args('queue_time', args)
            }

            params[:expires_at] = params[:enqueued_at] + klass.retry_ttl if klass.retry_ttl

            new(params).save!
          end
        end

        def finnish_job(klass, args)
          with_job(klass, args) do |job|
            return unless job
            return if job.finnished?
            job.update_attribute(:completed_at, Time.now)
          end
        end

        def trying_job(klass, args)
          with_job(klass, args) do |job|
            return unless job
            return if job.finnished?
            job.update_attributes(  :last_tried_at => Time.now,
                                    :attempt => job.attempt + 1)
          end
        end

        def fail_job(klass, args)
          with_job(klass, args) do |job|
            return unless job
            return if job.finnished?
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
          pertry_hash = args[Resque::Plugins::Pertry::JOB_HASH] || args[Resque::Plugins::Pertry::JOB_HASH.to_s] || {}
          pertry_hash[field]
        end

      end

      def completed?
        completed_at
      end
      
      def expired?
        expires_at < Time.now
      end

      def failed?
        failed_at
      end

      def finnished?
        completed? || failed? || expired?
      end

      def payload
        @payload ||= Resque.decode(arguments)
      end

      def resque_job
        job.constantize.instance(payload)
      end

    end
  end
end
