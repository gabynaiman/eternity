module Eternity
  class CollectionIndex

    extend Forwardable
    def_delegators :index, :to_h, :to_primitive, :empty?, :dump, :restore, :destroy, :count

    def initialize(options)
      @index = Restruct::Hash.new options
    end

    def collection_name
      index.id.sections.last
    end

    def [](id)
      return nil unless index.key? id
      Blob.new :data, index[id]
    end

    def insert(id, data)
      raise "#{collection_name.capitalize} #{id} already exists" if index.key? id
      index[id] = Blob.write :data, data
    end

    def update(id, data)
      raise "#{collection_name.capitalize} #{id} not found" unless index.key? id
      index[id] = Blob.write :data, data
    end

    def delete(id)
      raise "#{collection_name.capitalize} #{id} not found" unless index.key? id
      index.delete id
    end

    def ids
      index.keys
    end

    private

    attr_reader :index

  end
end