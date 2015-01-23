require 'coverage_helper'
require 'eternity'
require 'minitest/autorun'
require 'timeout'
require 'turn'
require 'pry-nav'
require 'database_cleaner'

include Eternity

Turn.config do |c|
  c.format = :pretty
  c.natural = true
  c.ansi = true
end

Eternity.configure do |config|
  config.keyspace = Restruct::Id.new :eternity_test
  config.data_path = File.expand_path('../../tmp', __FILE__)
  config.blob_cache_expiration = 30
  config.logger.level = Logger::ERROR
end

ActiveRecord::Base.logger = Eternity.logger
ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'
ActiveRecord::Migration.verbose = false
ActiveRecord::Migrator.migrate File.expand_path('../migrations', __FILE__)

Dir.glob(File.expand_path('../models/*.rb', __FILE__)).each { |f| require f }

class Minitest::Spec
  def redis
    Eternity.redis
  end

  def print_keys
    puts Eternity.redis_keys.sort
  end

  def digest(data)
    Blob.digest(Blob.serialize(data))
  end

  before do
    DatabaseCleaner.start
  end

  after do
    DatabaseCleaner.clean
    Eternity.clear_redis
    Eternity.clear_file_system
  end
end

module Minitest::Assertions
  def assert_equal_index(expected, commit)
    commit.with_index do |index|
      index.to_h.must_equal expected
    end
  end

  def assert_have_empty_index(commit)
    commit.with_index do |index|
      index.must_be_empty
    end
  end
end

Commit.infect_an_assertion :assert_equal_index, :must_equal_index
Commit.infect_an_assertion :assert_have_empty_index, :must_have_empty_index, :unary