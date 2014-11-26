require 'coverage_helper'
require 'eternity'
require 'minitest/autorun'
require 'turn'
require 'pry-nav'

include Eternity

Turn.config do |c|
  c.format = :pretty
  c.natural = true
  c.ansi = true
end

Eternity.configure do |config|
  config.namespace = Nido.new :eternity_test
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

  before do
    Eternity.clean_redis
    Eternity.clean_file_system
  end
end

module Minitest::Assertions
  def assert_equal_index(expected, actual)
    session = Session.new Digest::SHA1.hexdigest(actual.to_s)
    session.index.restore actual
    entries = session.index.entries
    session.destroy
    entries.must_equal expected
  end
end

Hash.infect_an_assertion :assert_equal_index, :must_equal_index

