module Resque
  module Pertry
    class ResquePertryPersistence < ActiveRecord::Base

      self.table_name = "resque_pertry_persistence"

      class << self

        def create_job(klass, args)
          new(  :audit_id => args[Resque::Pertry::Job::JOB_HASH][:audit_it], 
                :job => klass.to_s,
                :arguments => args.to_json, 
                :attempt => args[Resque::Pertry::Job::JOB_HASH][:attempt])
        end

      end

    end
  end
end
