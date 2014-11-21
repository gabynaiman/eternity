module Eternity
  class IndexSection

    attr_reader :index, :name, :key

    def initialize(index, name)
      @index = index
      @name = name.to_s
      @key = index.key[name]
      @delta = Delta.new index.session
    end
    
    def entries
      Eternity.redis.call('HGETALL', key).each_slice(2).to_h
    end

    def add(id, data)
      sha1 = Blob.write :data, data
      @delta.add name, id
      Eternity.redis.call 'HSET', key, id, sha1
    end

    def update(id, data)
      sha1 = Blob.write :data, data
      @delta.update name, id
      Eternity.redis.call 'HSET', key, id, sha1
    end

    def remove(id)
      @delta.remove name, id
      Eternity.redis.call 'HDEL', key, id
    end

    def revert(id)
      @delta.revert name, id
      tmp_key = Eternity.namespace[:tmp][index.session.head.id][:index][name]
      Eternity.redis.call 'RESTORE', tmp_key, 0, index.session.head.index_dump[name]
      sha1 = Eternity.redis.call 'HGET', tmp_key, id
      Eternity.redis.call 'HSET', key, id, sha1
      Eternity.redis.call 'DEL', tmp_key
    end

    def dump
      Eternity.redis.call 'DUMP', key
    end

    def restore(dump)
      Eternity.redis.call 'RESTORE', key, 0, dump
    end

    def destroy
      Eternity.redis.call 'DEL', key
    end

  end
end