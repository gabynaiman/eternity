module Eternity
  class Commit

    attr_reader :id

    def initialize(id)
      @id = id
      @data = Blob.read :commit, id
    end

    def time
      Time.parse @data['time']
    end

    def author
      @data['author']
    end

    def message
      @data['message']
    end

    def parent_ids
      @data['parents']
    end

    def parents
      parent_ids.map { |id| Commit.new id }
    end

    def index_id
      @data['index']
    end

    def index_dump
      Blob.read :index, index_id
    end

    def delta_id
      @data['delta']
    end

    def delta
      Blob.read :delta, delta_id
    end

    def to_h
      {'id' => id}.merge @data
    end

    def self.create(data)
      Blob.write :commit, data.merge(time: Time.now.strftime('%Y-%m-%dT%H:%M:%S%z'))
    end

  end
end