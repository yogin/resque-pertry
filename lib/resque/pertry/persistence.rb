module Resque
  module Pertry
    module Persistence
      extend ActiveSupport::Concern

      included do
        # define all jobs as persistent by default
        persistent
      end

      module ClassMethods

        # Set job as persistent
        def persistent
          properties[:persistent] = true
        end

        def non_persistent
          properties[:persistent] = false
        end

        # Check if job is persistent
        def persistent?
          !!properties[:persistent]
        end

        # Resque before_enqueue hook
        def before_enqueue_pertry_99_persistence(args = {})
          pertry_key = Resque::Plugins::Pertry::JOB_HASH.to_s

          args[pertry_key] ||= {}
          args[pertry_key]['audit_id'] ||= UUIDTools::UUID.random_create.to_s
          args[pertry_key]['queue_time'] ||= Time.now
          args[pertry_key]['persist'] = persistent?

          if persistent?
            ResquePertryPersistence.create_job_if_needed(self, args)
          end

          # continue with enqueue
          true
        end

        # Resque after_perform hook (job completed successfully)
        def after_perform_pertry_00_persistence(args = {})
          return unless persistent?

          ResquePertryPersistence.finnish_job(self, args)
        end

      end

    end
  end
end
