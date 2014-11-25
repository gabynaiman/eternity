module Eternity
  class DeltaSection

    attr_reader :delta, :name, :namespace
    
    def initialize(delta, name)
      @delta = delta
      @name = name
      @namespace = delta.namespace[name]
    end

    def add(id)
      if removed? id
        delete :removed, id
        register :updated, id
      else
        register :added, id
      end
    end

    def update(id)
      if !added?(id)
        register :updated, id
      end
    end

    def remove(id)
      if added? id
        delete :added, id
      else
        delete :updated, id
        register :removed, id
      end
    end

    def revert(id)
      [:added, :updated, :removed].each { |t| delete t, id }
    end

    [:added, :updated, :removed].each do |type|
      define_method "#{type}?" do |id|
        Eternity.redis.call('SISMEMBER', namespace[type], id) == 1
      end
    end

    private

    def register(type, id)
      Eternity.redis.call 'SADD', namespace[type], id
    end

    def delete(type, id)
      Eternity.redis.call 'SREM', namespace[type], id
    end
  end
end