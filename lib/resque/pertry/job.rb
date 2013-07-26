module Resque
  module Pertry
    class Job

      class << self

        def enqueue(args = {}, audit_id = nil)
          raise ArgumentError, "Invalid arguments, expecting a Hash but got: #{args.inspect}" unless Hash === args

          args.symbolize_keys!
          args = check_arguments(args)
          args[:_queue_time] = Time.now.to_i
          args[:_audit_id] = audit_id || UUIDTools::UUID.random_create.to_s

          Resque.enqueue(self, args)
        end

        def perform(args = {})
          raise ArgumentError, "Invalid arguments, expecting a Hash but got: #{args.inspect}" unless Hash === args

          args.symbolize_keys!
          new(check_arguments(args), args[:_queue_time], args[:_audit_id]).perform
        end

        def in_queue(queue)
          @queue = queue.to_sym
        end
        
        def queue
          @queue or raise ArgumentError, "No queue defined for job #{self.name}!"
        end

        def needs(*arguments)
          arguments.each do |argument|
            if Hash === argument
              argument.each do |key, default|
                self.required_arguments << { :argument => key, :default => default }
              end
            else
              self.required_arguments << { :argument => argument }
            end
          end
        end

        def required_arguments
          @required_arguments ||= []
        end

        private

        def check_arguments(provided_arguments)
          required_arguments.inject({}) do |checked_arguments, argument|
            raise ArgumentError, "Missing required argument #{argument[:argument]} from #{arguments.inspect}" unless provided_arguments.member?(argument[:argument] || argument.member?(:default)

            provided_argument = provided_arguments[argument[:argument]] || argument[:default]
            # TODO check that provided_argument is serializable as json
            checked_arguments[argument[:argument]] = provided_argument

            checked_arguments
          end
        end

      end

      def initialize(arguments, queue_time, audit_id)
        arguments.each do |key, val|
          instance_variable_set("@#{key}", val)
        end

        @_queue_time = Time.at(queue_time)
        @_audit_id = audit_id
      end

      def queue_time
        @_queue_time
      end

      def audit_id
        @_audit_id
      end

      def perform
        raise NoMethodError, "No method #{self.class.name}#perform defined!"
      end

    end
  end
end
