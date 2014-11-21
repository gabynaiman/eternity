require 'coverage_helper'
require 'eternity'
require 'minitest/autorun'
require 'turn'

Turn.config do |c|
  c.format = :pretty
  c.natural = true
  c.ansi = true
end

Eternity.redis.call 'FLUSHDB'
Eternity.logger.formatter = proc do |severity, datetime, progname, msg|
  "#{msg}\n"
end