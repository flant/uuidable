module Uuidable
  # ActiveRecord mixin
  module ActiveRecord
    extend ActiveSupport::Concern

    class UuidChangeError < RuntimeError; end

    module Finder
      def find(*args)
        if args.first && args.first.is_a?(String) && args.first.match(UUIDTools::UUID_REGEXP)
          find_by_uuid!(*args)
        else
          super
        end
      end
    end

    # ClassMethods
    module ClassMethods
      include Finder

      def uuidable(as_param: true)
        after_initialize { self.uuid = Uuidable.generate_uuid if attributes.keys.include?('uuid') && uuid.blank? }
        validates :uuid, presence: true, uniqueness: true

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
  ActiveRecord::Base.send(:include, Uuidable::ActiveRecord)
  ActiveRecord::Relation.send(:prepend, Uuidable::ActiveRecord::Finder)
end
