module Resque
  module Plugins
    class Pertry
      JOB_HASH = :_pertry

      include Resque::Pertry::Persistence
      include Resque::Pertry::Retry

      attr_reader :exception_handled

      class << self

        # Enqueue a job
        def enqueue(args = {})
          raise ArgumentError, "Invalid arguments, expecting a Hash but got: #{args.inspect}" unless Hash === args

          args.symbolize_keys!
          args = check_arguments(args)
          raise ArgumentError, "Invalid arguments, #{JOB_HASH} is a reserved argument!" if args.key?(JOB_HASH)

          Resque.enqueue(self, args)
        end

        # Perform a job
        def perform(args = {})
          raise ArgumentError, "Invalid arguments, expecting a Hash but got: #{args.inspect}" unless Hash === args

          begin
            job = instance(args)
            job.perform
          rescue => e
            job.handle_exception(e)
            raise unless job.exception_handled
          end
        end

        def instance(args = {})
          args.symbolize_keys!
          raise ArgumentError, "Job is not supported, missing key #{JOB_HASH} from payload #{args.inspect}" unless args.key?(JOB_HASH)

          new(check_arguments(args), args[JOB_HASH])
        end

        # Specificy job queue
        def in_queue(queue)
          @queue = queue.to_sym
        end
        
        # Get job queue
        def queue
          @queue or raise ArgumentError, "No queue defined for job #{self.name}!"
        end

        # Define required job attributes
        def needs(*arguments)
          arguments.each do |argument|
            if Hash === argument
              argument.each do |key, default|
                self.required_arguments << { :name => key, :default => default }
              end
            else
              self.required_arguments << { :name => argument }
            end
          end
        end

        # List of required attributes
        def required_arguments
          @required_arguments ||= []
        end

        private

        # Check that job arguments match required arguments
        def check_arguments(provided_arguments)
          required_arguments.inject({}) do |checked_arguments, argument|
            raise ArgumentError, "#{self} is missing required argument #{argument[:name]} from #{provided_arguments.inspect}" unless provided_arguments.member?(argument[:name]) || argument.member?(:default)

            provided_argument = provided_arguments[argument[:name]] || argument[:default]
            # TODO check that provided_argument is serializable as json

            checked_arguments[argument[:name]] = provided_argument
            checked_arguments
          end
        end

      end

      def initialize(arguments, job_properties)
        set_job_arguments(arguments)
        set_job_properties(job_properties)
      end

      # Perform method needs to be overridden in job classes
      def perform
        raise NoMethodError, "No method #{self.class.name}#perform defined!"
      end

      def handle_exception(exception)
        # we don't handle exceptions by default, leave it for resque
        # when overridding this method, if you decide you want to completely
        # handle it, and not pass it back to resque, you'll need to call
        # exception_handled!
      end

      def exception_handled
        @exception_handled ||= false
      end

      def exception_handled!
        @exception_handled = true
      end

      # mark job as failed, won't be retried
      def fail!
        Resque::Pertry::ResquePertryPersistence.fail_job(self.class, payload)
      end
      alias_method :fail_job!, :fail!

      # mark job as complete
      def complete!
        Resque::Pertry::ResquePertryPersistence.finnish_job(self.class, payload)
      end
      alias_method :complete_job!, :complete!

      def arguments
        @_arguments
      end

      def payload
        @_arguments.merge(JOB_HASH => @_job_properties)
      end

      private

      def set_job_properties(hash)
        @_job_properties ||= {}
        @_job_properties.merge!(hash)
      end

      def set_job_arguments(hash)
        @_arguments = hash
        arguments.each do |key, val|
          instance_variable_set("@#{key}", val)
        end
      end

    end
  end
end
