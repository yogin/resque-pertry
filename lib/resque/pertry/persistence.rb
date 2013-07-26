module Resque
  module Pertry
    module Persistence
      extend ActiveSupport::Concern

      module ClassMethods

        # Set job as persistent
        def persistent
          @persistent = true
        end

        def non_persistent
          @persistent = false
        end

        # Check if job is persistent
        def persistent?
          !!@persistent
        end

        # Resque before_enqueue hook
        def before_enqueue_pertry_persistence(args = {})
          args[Resque::Pertry::Job::JOB_HASH] ||= {}
          args[Resque::Pertry::Job::JOB_HASH][:audit_it] = UUIDTools::UUID.random_create.to_s
          args[Resque::Pertry::Job::JOB_HASH][:queue_time] = Time.now.to_i
          args[Resque::Pertry::Job::JOB_HASH][:persist] = persistent?

          # continue with enqueue
          true
        end

      end

    end
  end
end
