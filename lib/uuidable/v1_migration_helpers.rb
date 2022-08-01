# frozen_string_literal: true

module Uuidable
  module V1MigrationHelpers
    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    # Will create uuid columns with new type, move data from pre-v1 column and then move pre-v1 to *__old.
    # WARNING: will only work on MySQL 8+.
    def uuidable_migrate_uuid_columns_to_v1(table_name, **columns)
      change_table table_name, bulk: true do |t|
        columns.each do |column, options|
          t.column :"#{column}_new", :binary, COLUMN_OPTIONS.merge(options).merge(after: column)
        end
      end

      update = columns.map do |column, _opts|
        <<~SQL
          `#{table_name}`.`#{column}_new` = IF(
            IS_UUID(`#{table_name}`.`#{column}`),
            UUID_TO_BIN(`#{table_name}`.`#{column}`),
            `#{table_name}`.`#{column}`
          )
        SQL
      end.join(', ')

      execute "UPDATE `#{table_name}` SET #{update}"

      # we can't use bulk because of automatic index rename
      change_table table_name, bulk: false do |t|
        columns.each do |column, _options|
          t.rename column, :"#{column}__old"
          t.rename :"#{column}_new", column
        end
      end
    end

    # WARNING: will only work until *__old columns is not deleted!
    def uuidable_rollback_uuid_columns_from_v1(table_name, *columns)
      # we can't use bulk because of automatic index rename
      change_table table_name, bulk: false do |t|
        columns.each do |column|
          t.rename column, :"#{column}_new"
          t.rename :"#{column}__old", column
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

    def uuidable_migrate_all_pre_v1_uuid_columns!(skip: nil)
      skip = Array.wrap(skip).each(&:to_s)

      tables.each do |table_name|
        indexes = indexes(table_name)
        uuid_columns = connection.columns(table_name).select do |column|
          column.name.include?('uuid') &&
            column.type == :binary &&
            column.sql_type_metadata.limit == 36 &&
            !skip.include?("#{table_name}.#{column.name}")
        end

        next if uuid_columns.blank?

        migrate_params = uuid_columns.map do |column|
          [column.name.to_sym, { null: column.null }]
        end.to_h

        uuidable_migrate_uuid_columns_to_v1 table_name, **migrate_params

        change_table table_name, bulk: true do |t|
          uuid_columns.each do |column|
            indexes.each do |ind|
              next unless ind.columns.include?(column.name)

              t.index ind.columns, name: ind.name, unique: ind.unique
            end
          end
        end
      end
    end

    def uuidable_rollback_all_pre_v1_uuid_columns!
      tables.each do |table_name|
        uuid_columns = connection.columns(table_name).select do |column|
          column.name.include?('uuid') &&
            column.type == :binary &&
            column.sql_type_metadata.limit == 16
        end

        next if uuid_columns.blank?

        uuidable_rollback_uuid_columns_from_v1 table_name, *uuid_columns.map(&:name)
      end
    end

    # WARNING: this is irreversible migration! It will drop all *uuid__old columns and their indexes in all tables!
    def uuidable_drop_all_pre_v1_uuid_columns!
      tables.each do |table_name|
        indexes = indexes(table_name)
        change_table table_name, bulk: true do |t|
          connection.columns(table_name).each do |column|
            next unless column.name.include?('uuid__old')

            indexes.each do |ind|
              next unless ind.columns.include?(column.name)

              t.remove_index name: ind.name
            end

            t.remove column.name
          end
        end
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  end
end
