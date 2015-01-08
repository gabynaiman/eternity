module Restruct
  class Array < Object

    include Enumerable

    def [](index)
      redis.call 'LINDEX', key, index
    end

    def push(element)
      redis.call 'RPUSH', key, element
    end
    alias_method :<<, :push

    def size
      redis.call 'LLEN', key
    end
    alias_method :count, :size
    alias_method :length, :size

    def each
      size.times do |index|
        yield self[index]
      end
    end

    def last
      self[size - 1]
    end

  end
end