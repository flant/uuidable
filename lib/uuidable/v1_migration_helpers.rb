# frozen_string_literal: true

# rubocop:disable all
module Uuidable
  module V1MigrationHelpers
    NEW_POSTFIX = '__new'
    OLD_POSTFIX = '__old'

    # Will create uuid columns with new type, move data from pre-v1 column and then move pre-v1 to *__old.
    # WARNING: will only work on MySQL 8+.
    def uuidable_migrate_uuid_columns_to_v1(table_name, columns_options = {}, **opts)
      columns_options.stringify_keys!
      uuid_columns = connection.columns(table_name).select do |column|
        (columns_options.blank? || columns_options.key?(column.name)) &&
          valid_column_for_migration?(column, opts)
      end

      return if uuid_columns.blank?

      change_table table_name, bulk: true do |t|
        uuid_columns.each do |column|
          options = columns_options[column.name] || { null: column.null }
          t.column :"#{column.name}#{NEW_POSTFIX}", :binary, **COLUMN_OPTIONS.merge(options).merge(after: column.name)
        end
      end

      update = uuid_columns.map do |column, _opts|
        <<~SQL
          `#{table_name}`.`#{column.name}#{NEW_POSTFIX}` = IF(
            IS_UUID(`#{table_name}`.`#{column.name}`),
            UUID_TO_BIN(`#{table_name}`.`#{column.name}`),
            `#{table_name}`.`#{column.name}`
          )
        SQL
      end.join(', ')

      execute "UPDATE `#{table_name}` SET #{update}"

      # bulk will not rename indexes so we could just reindex them
      change_table table_name, bulk: true do |t|
        uuid_columns.each do |column|
          t.rename column.name, :"#{column.name}#{OLD_POSTFIX}"
          t.rename :"#{column.name}#{NEW_POSTFIX}", column.name
        end
      end

      # reindex indexes
      connection.execute "OPTIMIZE TABLE `#{table_name}`"
    end

    # WARNING: will only work until *__old columns is not deleted!
    def uuidable_rollback_uuid_columns_from_v1(table_name, *columns)
      columns.map!(&:to_s)
      uuid_columns = connection.columns(table_name).select do |column|
        (columns.blank? || columns.include?(column.name)) &&
        valid_column_for_migration?(column, limit: 16)
      end

      return if uuid_columns.blank?

      change_table table_name, bulk: true do |t|
        uuid_columns.each do |column|
          t.rename column.name, :"#{column.name}#{NEW_POSTFIX}"
          t.rename :"#{column.name}#{OLD_POSTFIX}", column.name
        end
      end

      change_table table_name, bulk: true do |t|
        uuid_columns.each do |column|
          t.remove :"#{column.name}#{NEW_POSTFIX}"
        end
      end

      # reindex indexes
      connection.execute "OPTIMIZE TABLE `#{table_name}`"
    end

    def uuidable_migrate_all_pre_v1_uuid_columns!
      tables.each do |table_name|
        uuidable_migrate_uuid_columns_to_v1 table_name
      end
    end

    def uuidable_rollback_all_pre_v1_uuid_columns!
      tables.each do |table_name|
        uuidable_rollback_uuid_columns_from_v1 table_name
      end
    end

    # WARNING: this is irreversible migration! It will drop all *uuid__old columns and their indexes in all tables!
    def uuidable_drop_all_pre_v1_uuid_columns!
      tables.each do |table_name|
        indexes = indexes(table_name)
        change_table table_name, bulk: true do |t|
          connection.columns(table_name).each do |column|
            next unless column.name.include?(OLD_POSTFIX)

            indexes.each do |ind|
              next unless ind.columns.include?(column.name)

              t.remove_index name: ind.name
            end

            t.remove column.name
          end
        end
      end
    end

    def valid_column_for_migration?(column, limit: 36, skip_type_check: false)
      column.name.include?('uuid') &&
        !column.name.include?(NEW_POSTFIX) &&
        !column.name.include?(OLD_POSTFIX) &&
        (skip_type_check || (
          column.type == :binary &&
          column.limit == limit
        ))
    end
  end
end
# rubocop:enable all
