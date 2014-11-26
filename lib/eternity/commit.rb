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

    def self.create(data)
      params = {
        time:    Time.now.strftime('%Y-%m-%dT%H:%M:%S%z'),
        author:  data.fetch(:author),
        message: data.fetch(:message),
        parents: data.fetch(:parents),
        index:   data.fetch(:index),
        delta:   data.fetch(:delta)
      }
      Blob.write :commit, params
    end

  end
end