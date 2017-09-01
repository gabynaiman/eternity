require 'digest/sha1'
require 'msgpack'
require 'class_config'
require 'logger'
require 'fileutils'
require 'forwardable'
require 'restruct'
require 'base64'
require 'transparent_proxy'

module Eternity

  INSERT = 'insert'.freeze
  UPDATE = 'update'.freeze
  DELETE = 'delete'.freeze

  TIME_FORMAT = '%Y-%m-%dT%H:%M:%S%z'

  extend ClassConfig

  attr_config :connection, Restruct::Connection.new
  attr_config :keyspace, Restruct::Id.new(:eternity)
  attr_config :blob_cache_expiration, 24 * 60 * 60 # 1 day in seconds
  attr_config :blob_cache_max_size, 10 * 1024 * 1024 # 10 MB
  attr_config :blob_path, File.join(Dir.home, '.eternity')
  attr_config :logger, Logger.new(STDOUT)

  def self.locker_for(repository_name)
    Restruct::Locker.new  connection: connection,
                          id: keyspace[:locker][:repository][repository_name]
  end
 
  def self.redis_keys
    connection.call 'KEYS', keyspace['*']
  end

  def self.clear_redis
    redis_keys.each do |key|
      connection.call 'DEL', key
    end
  end

  def self.clear_file_system
    FileUtils.rm_rf blob_path if Dir.exist? blob_path
  end

end

require_relative 'eternity/version'
require_relative 'eternity/blob'
require_relative 'eternity/repository'
require_relative 'eternity/object_tracker'
require_relative 'eternity/collection_tracker'
require_relative 'eternity/tracker'
require_relative 'eternity/collection_index'
require_relative 'eternity/index'
require_relative 'eternity/commit'
require_relative 'eternity/branch'
require_relative 'eternity/patch'
require_relative 'eternity/track_flatter'
require_relative 'eternity/conflict_resolver'
require_relative 'eternity/delta'