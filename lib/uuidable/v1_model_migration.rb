# frozen_string_literal: true

module Uuidable
  # Temporary helpers for transition period when migrating to v1
  module V1ModelMigration
    extend ActiveSupport::Concern

    included do
      before_validation do
        attributes.each_key do |attr_name|
          next unless attr_name.include?(V1MigrationHelpers::OLD_POSTFIX)

          new_attr_name = attr_name.gsub(V1MigrationHelpers::OLD_POSTFIX, '')
          public_send("#{attr_name}=", attributes[new_attr_name].to_s)
        end
      end
    end
  end
end
