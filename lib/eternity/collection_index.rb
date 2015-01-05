module Eternity
  class CollectionIndex

    DELEGATES = [:key?, :keys, :count, :size, :length]

    def initialize(options)
      @index = options.delete :parent
      @delta = Delta.new index.session
      @hash = Restruct::Hash.new options
    end

    def name
      hash.key.sections.last
    end

    DELEGATES.each do |method|
      define_method method do |*args, &block|
        hash.send method, *args, &block
      end
    end

    def [](id)
      Blob.new :data, hash[id]
    end

    def each
      hash.keys.each do |id|
        yield id, self[id]
      end
    end

    def add(id, data)
      raise "Index add error. #{name.capitalize} #{id} already exists" if key? id

      sha1 = Blob.write :data, data
      delta[name].add id
      hash[id] = sha1
    end

    def update(id, data)
      raise "Index update error. #{name.capitalize} #{id} not found" unless key? id

      sha1 = Blob.write :data, data
      delta[name].update id
      hash[id] = sha1
    end

    def remove(id)
      raise "Index remove error. #{name.capitalize} #{id} not found" unless key? id

      delta[name].remove id
      hash.delete id
    end

    def revert(id)
      raise "Index revert error. #{name.capitalize} #{id} not found" unless key?(id) || delta[name].removed?(id)

      delta[name].revert id
      if index.session.current_commit?
        index.session.current_commit.with_index do |tmp_index|
          hash[id] = tmp_index[name][id].sha1
        end
      else
        hash.delete id
      end
    end

    def dump
      hash.dump
    end

    def restore(dump)
      hash.restore dump
    end

    def destroy
      hash.destroy
    end

    def to_h
      hash.to_h
    end
    alias_method :to_primitive, :to_h

    private

    attr_reader :hash, :index, :delta

  end
end