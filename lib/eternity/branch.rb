module Eternity
  class Branch

    attr_reader :name

    def initialize(name)
      @name = name
    end

    def commit_id
      Eternity.redis.call 'HGET', Eternity.namespace[:branches], name
    end

    def commit_id=(id)
      Eternity.redis.call 'HSET', Eternity.namespace[:branches], name, id
    end

    def self.exists?(name)
      Eternity.redis.call('HEXISTS', Eternity.namespace[:branches], name) == 1
    end

  end
end