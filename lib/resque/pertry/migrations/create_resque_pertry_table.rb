module Resque
  module Pertry
    module Migrations
      class CreateResquePertryTable < ActiveRecord::Migration

        def up
          create_table :resque_pertry_persistence do |t|
            t.string :audit_id, :null => false, :limit => 64
            t.string :job, :null => false
            t.text :arguments, :null => false, :limit => 64.kilobytes + 1
            t.integer :attempt, :default => 1
            t.datetime :enqueued_at
            t.datetime :completed_at
            t.datetime :failed_at
            t.datetime :last_tried_at
            t.datetime :expires_at
            t.timestamps
          end

          add_index :resque_pertry_persistence, :audit_id, :unique => true
        end

        def down
          drop_table :resque_pertry_persistence
        end

      end
    end
  end
end
