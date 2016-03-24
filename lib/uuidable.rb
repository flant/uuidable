require 'uuidable/version'
require 'uuidable/migration'

require 'active_support'

# Main module
module Uuidable
  extend ActiveSupport::Concern

  class UuidChangeError < Exception; end

  # ClassMethods
  module ClassMethods
    def uuidable
      after_initialize { self.uuid = self.class.generate_uuid if uuid.blank? }
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

  def self.generate_uuid
    SecureRandom.uuid
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.send(:include, Uuidable)
end
