module Resque
  module Pertry
    module Persistence
      extend ActiveSupport::Concern

      included do
        class_attribute :_persistent

        # define all jobs as persistent by default
        persistent
      end

      module ClassMethods
        
        # Set job as persistent
        def persistent
          self._persistent = true
        end
        alias_method :durable, :persistent

        def non_persistent
          self._persistent = false
        end
        alias_method :non_durable, :non_persistent

        # Check if job is persistent
        def persistent?
          !!self._persistent
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

      def audit_id
        @_job_properties['audit_id']
      end

      def queue_time
        @_job_properties['queue_time']
      end

    end
  end
end
