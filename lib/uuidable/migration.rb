module Uuidable
  COLUMN_NAME = :uuid
  COLUMN_TYPE = :binary
  COLUMN_OPTIONS = { limit: 36, null: false, index: true }.freeze

  # Module adds method to table definition
  module TableDefinition
    def uuid(opts = {})
      column COLUMN_NAME, COLUMN_TYPE, opts.merge(COLUMN_OPTIONS)
    end
  end

  # Module adds method to alter table migration
  module Migration
    def add_uuid_column(table_name, opts = {})
      add_column table_name, COLUMN_NAME, COLUMN_TYPE, opts.merge(COLUMN_OPTIONS)
    end
  end
end
if defined? ActiveRecord::ConnectionAdapters::TableDefinition
  ActiveRecord::ConnectionAdapters::TableDefinition.send :include, Uuidable::TableDefinition
end

ActiveRecord::Migration.send :include, Uuidable::Migration if defined? ActiveRecord::Migration
