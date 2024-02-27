# frozen_string_literal: true

require 'uuidable/version'
require 'active_model'
require 'uuidtools'

require 'mysql-binuuid-rails'

# Main module
module Uuidable
  module_function

  def generate_uuid
    SecureRandom.uuid
  end
end

require 'uuidable/migration'
require 'uuidable/v1_migration_helpers'
require 'uuidable/active_record'
