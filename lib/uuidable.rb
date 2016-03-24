require 'uuidable/version'
require 'active_support'

# Main module
module Uuidable
  module_function

  def generate_uuid
    SecureRandom.uuid
  end
end

require 'uuidable/migration'
require 'uuidable/active_record'
