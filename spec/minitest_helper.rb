require 'coverage_helper'
require 'eternity'
require 'minitest/autorun'
require 'timeout'
require 'turn'
require 'pry-nav'

include Eternity

Turn.config do |c|
  c.format = :pretty
  c.natural = true
  c.ansi = true
end

Eternity.configure do |config|
  config.keyspace = Restruct::Key.new :eternity_test
  config.data_path = File.expand_path('../../tmp', __FILE__)
  config.blob_cache_expiration = 30
  config.logger.formatter = ->(_,_,_,m) { "#{m}\n" }
end

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

  after do
    Eternity.clean_redis
    Eternity.clean_file_system
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