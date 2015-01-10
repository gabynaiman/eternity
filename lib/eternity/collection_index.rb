module Eternity
  class CollectionIndex

    extend Forwardable
    def_delegators :hash, :to_h, :to_primitive, :empty?, :dump, :restore, :destroy

    def initialize(options)
      @hash = Restruct::Hash.new options
    end

    def collection_name
      hash.key.sections.last
    end

    def insert(id, data)
      raise "#{collection_name.capitalize} #{id} already exists" if hash.key? id
      hash[id] = Blob.write :data, data
    end

    def update(id, data)
      raise "#{collection_name.capitalize} #{id} not found" unless hash.key? id
      hash[id] = Blob.write :data, data
    end

    def delete(id)
      raise "#{collection_name.capitalize} #{id} not found" unless hash.key? id
      hash.delete id
    end

    private

    attr_reader :hash

  end
end