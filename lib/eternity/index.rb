module Eternity
  class Index < Restruct::NestedHash.new(CollectionIndex)

    attr_reader :name

    def initialize(name=nil)
      @name = name ? name.to_s : SecureRandom.uuid
      super connection: Eternity.connection,
            id: Eternity.keyspace[:index][@name]
    end

    def apply(delta)
      delta.each do |collection, elements|
        elements.each do |id, change|
          args = [id, change['data']].compact
          self[collection].send change['action'], *args
        end
      end
    end

    def write_blob
      Blob.write :index, dump
    end

    def self.read_blob(sha1)
      Index.new.tap do |index|
        index.restore Blob.read :index, sha1
      end
    end

    def self.all
      sections_count = Eternity.keyspace[:index].sections.count
      names = Eternity.connection.call('KEYS', Eternity.keyspace[:index]['*']).map do |key|
        Restruct::Id.new(key).sections[sections_count]
      end.uniq
      names.map { |name| new name }
    end

  end
end