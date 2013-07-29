module Resque
  module Pertry
    class ResquePertryPersistence < ActiveRecord::Base

      self.table_name = "resque_pertry_persistence"

      class << self

        def create_job(klass, args)
          new(  :audit_id => field_from_args('audit_id', args),
                :job => klass.to_s,
                :arguments => args.to_json, 
                :attempt => 0,
                :enqueued_at => field_from_args('queue_time', args)).save!
        end

        def finnish_job(klass, args)
          $stdout.puts "finnishing job #{klass} with #{args.inspect}"

          with_job(klass, args) do |job|
            job.update_attribute(:completed_at, Time.now)
          end
       end

        def trying_job(klass, args)
          $stdout.puts "trying job #{klass} with #{args.inspect}"

          with_job(klass, args) do |job|
              job.update_attributes(  :last_tried_at => Time.now,
                                      :attempt => job.attempt + 1)
          end
        end

        private

        def field_from_args(field, args)
          pertry_hash = args[Resque::Pertry::Job::JOB_HASH] || args[Resque::Pertry::Job::JOB_HASH.to_s] || {}
          pertry_hash[field]
        end

        def with_job(klass, args, &block)
          audit_id = field_from_args('audit_id', args)
          return unless audit_id
          
          job = find_by_audit_id(audit_id)
          block.call(job) if block_given?
        end

      end

    end
  end
end
