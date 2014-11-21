require 'redic'
require 'digest/sha1'
require 'msgpack'
require 'class_config'
require 'nido'
require 'logger'

require_relative 'eternity/version'

require_relative 'eternity/blob'
require_relative 'eternity/commit'
require_relative 'eternity/session'
require_relative 'eternity/index'
require_relative 'eternity/index_section'
require_relative 'eternity/delta'

module Eternity
  extend ClassConfig

  attr_config :redis, Redic.new
  attr_config :namespace, Nido.new(:git)
  attr_config :logger, Logger.new(STDOUT)
end