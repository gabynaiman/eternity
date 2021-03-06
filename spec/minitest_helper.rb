require 'coverage_helper'
require 'eternity'
require 'minitest/autorun'
require 'minitest/colorin'
require 'minitest/great_expectations'
require 'timeout'
require 'pry-nav'

include Eternity

Eternity.configure do |config|
  config.keyspace = Restruct::Id[:eternity_test]
  config.blob_path = File.expand_path('../../tmp', __FILE__)
  config.blob_cache_expiration = 30
  config.blob_cache_max_size = 50
  config.logger.level = Logger::ERROR
end

class Minitest::Spec
  def connection
    Eternity.connection
  end

  def digest(data)
    Blob.digest(Blob.serialize(data))
  end

  after do
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