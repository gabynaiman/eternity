module Restruct
  class Hash < Object

    def [](field)
      redis.call 'HGET', key, field
    end

    def []=(field, value)
      redis.call 'HSET', key, field, value
    end

    def delete(field)
      value = self[field]
      redis.call 'HDEL', key, field
      value
    end

    def keys
      redis.call 'HKEYS', key
    end

    def values
      redis.call 'HVALS', key
    end

    def key?(field)
      redis.call('HEXISTS', key, field) == 1
    end

    def empty?
      redis.call('HLEN', key) == 0
    end

    def to_h
      ::Hash[redis.call('HGETALL', key).each_slice(2).to_a]
    end
    alias_method :to_primitive, :to_h

    def each
      keys.each { |field| yield field, self[field] }
    end

  end
end