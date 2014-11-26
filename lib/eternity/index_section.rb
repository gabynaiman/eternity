module Eternity
  class IndexSection

    attr_reader :index, :name, :namespace

    def initialize(index, name)
      @index = index
      @name = name.to_s
      @namespace = index.namespace[name]
      @delta = Delta.new index.session
    end
    
    def entries
      Hash[Eternity.redis.call('HGETALL', namespace).each_slice(2).to_a]
    end

    def key?(id)
      Eternity.redis.call('HEXISTS', namespace, id) == 1
    end

    def add(id, data)
      raise "Index add error. #{name.capitalize} #{id} already exists" if key? id

      sha1 = Blob.write :data, data
      delta[name].add id
      Eternity.redis.call 'HSET', namespace, id, sha1
    end

    def update(id, data)
      raise "Index update error. #{name.capitalize} #{id} not found" unless key? id

      sha1 = Blob.write :data, data
      delta[name].update id
      Eternity.redis.call 'HSET', namespace, id, sha1
    end

    def remove(id)
      raise "Index remove error. #{name.capitalize} #{id} not found" unless key? id

      delta[name].remove id
      Eternity.redis.call 'HDEL', namespace, id
    end

    def revert(id)
      raise "Index revert error. #{name.capitalize} #{id} not found" unless key?(id) || delta[name].removed?(id)

      delta[name].revert id
      if index.session.current_commit?
        tmp_namespace = Eternity.namespace[:tmp][index.session.current_commit_id][:index][name]
        Eternity.redis.call 'RESTORE', tmp_namespace, 0, index.session.current_commit.index_dump[name]
        sha1 = Eternity.redis.call 'HGET', tmp_namespace, id
        Eternity.redis.call 'HSET', namespace, id, sha1
        Eternity.redis.call 'DEL', tmp_namespace
      else
        Eternity.redis.call 'HDEL', namespace, id
      end
    end

    def dump
      Eternity.redis.call 'DUMP', namespace
    end

    def restore(dump)
      Eternity.redis.call 'RESTORE', namespace, 0, dump
    end

    def destroy
      Eternity.redis.call 'DEL', namespace
    end

    private

    attr_reader :delta

  end
end