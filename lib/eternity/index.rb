module Eternity
  class Index < Restruct::NestedHash.new(CollectionIndex)

    def initialize
      super connection: Eternity.connection,
            id: Eternity.keyspace[:index][SecureRandom.uuid]
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

    def self.keys
      Eternity.connection.call 'KEYS', Eternity.keyspace[:index]['*']
    end

  end
end