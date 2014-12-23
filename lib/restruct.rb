require 'redic'
require 'class_config'
require 'securerandom'
require 'set'

require_relative 'restruct/key'
require_relative 'restruct/object'
require_relative 'restruct/hash'
require_relative 'restruct/set'
require_relative 'restruct/nested_hash'

module Restruct

  extend ClassConfig

  attr_config :redis, Redic.new
  attr_config :key_separator, ':'
  attr_config :key_generator, ->() { SecureRandom.uuid }

  def self.generate_key
    Key.new key_generator.call
  end

end