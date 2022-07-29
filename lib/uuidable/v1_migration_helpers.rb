# frozen_string_literal: true

module Uuidable
  module V1MigrationHelpers
    # Will create uuid columns with new type, move data from pre-v1 column and then move pre-v1 to *_old.
    # WARNING: will only work on MySQL 8+.
    def uuidable_migrate_uuid_columns_to_v1(table_name, **columns)
      change_table table_name, bulk: true do |t|
        columns.each do |column, options|
          t.column :"#{column}_new", :binary, COLUMN_OPTIONS.merge(options).merge(after: column)
        end
      end

      update = columns.map { |column, _opts| "#{column}_new=IF(IS_UUID(#{column}), UUID_TO_BIN(#{column}), #{column})" }.join(', ')
      execute "UPDATE #{table_name} SET #{update}"

      # we can't use bulk because of automatic index rename
      change_table table_name, bulk: false do |t|
        columns.each do |column, _options|
          t.rename column, :"#{column}_old"
          t.rename :"#{column}_new", column
        end
      end
    end

    # WARNING: will only work until *_old columns is not deleted!
    def uuidable_rollback_uuid_columns_from_v1(table_name, *columns)
      # we can't use bulk because of automatic index rename
      change_table table_name, bulk: false do |t|
        columns.each do |column|
          t.rename column, :"#{column}_new"
          t.rename :"#{column}_old", column
        end
      end

      change_table table_name, bulk: true do |t|
        columns.each do |column|
          indexes(table_name).each do |ind|
            next unless ind.columns.include?("#{column}_new")

            t.remove_index name: ind.name
          end

          t.remove :"#{column}_new"
        end
      end
    end

    # WARNING: this is irreversible migration! It will drop all *uuid_old columns and their indexes in all tables!
    def uuidable_drop_all_pre_v1_uuid_columns!
      tables.each do |table_name|
        change_table table_name, bulk: true do |t|
          indexes = indexes(table_name)
          connection.columns(table_name).each do |column|
            next unless column.name.include?('uuid_old')

            indexes.each do |ind|
              next unless ind.columns.include?(column.name)

              t.remove_index name: ind.name
            end

            t.remove column.name
          end
        end
      end
    end
  end
end
