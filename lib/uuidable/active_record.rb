module Uuidable
  # ActiveRecord mixin
  module ActiveRecord
    extend ActiveSupport::Concern

    class UuidChangeError < Exception; end

    # ClassMethods
    module ClassMethods
      def uuidable
        after_initialize { self.uuid = Uuidable.generate_uuid if uuid.blank? }
        validates :uuid, presence: true, uniqueness: true

        define_method :to_param do
          uuid
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
end
