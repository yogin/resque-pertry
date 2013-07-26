module Resque
  module Pertry
    module Persistence
      extend ActiveSupport::Concern

      module ClassMethods

        # Set job as persistent
        def persistent
          @persistent = true
        end

        # Check if job is persistent
        def persistent?
          @persistent
        end

      end

      # Create persistent job
      def persist!
        # TODO add job to database
      end

    end
  end
end
