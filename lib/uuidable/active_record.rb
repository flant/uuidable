# frozen_string_literal: true

module Uuidable
  # ActiveRecord mixin
  module ActiveRecord
    extend ActiveSupport::Concern

    class UuidChangeError < RuntimeError; end

    module Finder
      def find(*args)
        if args.first.is_a?(String) && args.first&.match(UUIDTools::UUID_REGEXP)
          find_by_uuid!(*args)
        else
          super
        end
      end
    end

    # ClassMethods
    module ClassMethods
      include Finder

      def uuidable(as_param: true) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        # Configure all uuid columns for MySQL. Database may not be connected (i.e. on assets precompile), so we must supress errors.
        conn_config = respond_to?(:connection_db_config) ? connection_db_config.configuration_hash : connection_config
        if conn_config[:adapter].include?('mysql')
          begin
            columns.select { |c| c.type == :binary && c.limit == 16 && c.name.include?('uuid') }.each do |column|
              attribute column.name.to_sym, MySQLBinUUID::Type.new
            end
          rescue ::ActiveRecord::ConnectionNotEstablished, Mysql2::Error::ConnectionError, ::ActiveRecord::NoDatabaseError # rubocop:disable Lint/SuppressedException
          end
        end

        after_initialize do
          self.uuid = Uuidable.generate_uuid if attributes.keys.include?('uuid') && uuid.blank?
          self.uuid__old = uuid if respond_to?(:uuid__old)
        end

        validates :uuid, presence: true, uniqueness: true, if: :uuid_changed?

        if as_param
          define_method :to_param do
            uuid
          end
        end

        define_method :uuid= do |val|
          raise UuidChangeError, 'Uuid changing is bad idea!' unless new_record? || uuid.blank? || uuid == val

          super(val)
        end
      end
    end

    def short_uuid
      UUIDTools::UUID.parse(uuid).hexdigest
    end
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.include Uuidable::ActiveRecord
  ActiveRecord::Relation.prepend Uuidable::ActiveRecord::Finder
end
