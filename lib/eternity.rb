require 'redic'
require 'digest/sha1'
require 'msgpack'
require 'class_config'
require 'logger'
require 'fileutils'
require 'securerandom'

require_relative 'restruct'

module Eternity

  ADDED   = 'added'.freeze
  UPDATED = 'updated'.freeze
  REMOVED = 'removed'.freeze

  EVENTS = [ADDED, UPDATED, REMOVED].freeze

  extend ClassConfig

  attr_config :redis, Redic.new
  attr_config :keyspace, Restruct::Key.new(:eternity)
  attr_config :blob_cache_expiration, 24 * 60 * 60 # 1 day in seconds
  attr_config :data_path, File.join(Dir.home, '.eternity')
  attr_config :logger, Logger.new(STDOUT)

  def self.redis_keys
    redis.call 'KEYS', keyspace['*']
  end

  def self.clean_redis
    redis_keys.each do |key|
      redis.call 'DEL', key
    end
  end

  def self.clean_file_system
    FileUtils.rm_rf data_path if Dir.exists? data_path
  end

end

require_relative 'eternity/version'

require_relative 'eternity/blob'
require_relative 'eternity/branch'
require_relative 'eternity/commit'
require_relative 'eternity/session'
require_relative 'eternity/collection_index'
require_relative 'eternity/index'
require_relative 'eternity/collection_delta'
require_relative 'eternity/delta'
require_relative 'eternity/patch'
require_relative 'eternity/conflict_resolver'