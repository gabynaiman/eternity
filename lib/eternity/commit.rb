module Eternity
  class Commit

    attr_reader :id

    def initialize(id)
      @id = id
    end

    def time
      Time.parse data['time']
    end

    def author
      data['author']
    end

    def message
      data['message']
    end

    def parent_ids
      data['parents']
    end

    def parents
      parent_ids.map { |id| Commit.new id }
    end

    def index
      Index.read_blob data['index']
    end

    def delta
      Blob.read :delta, data['delta']
    end

    def base
      Commit.new data['base'] if data['base']
    end

    def fast_forward?(commit)
      return commit.nil? if base.nil?
      base.id == commit.id || base.fast_forward?(commit)
    end
    
    def self.create(options)
      data = {
        time:       Time.now,
        author:     options.fetch(:author),
        message:    options.fetch(:message),
        parents:    options.fetch(:parents),
        index:      options.fetch(:index),
        delta:      options.fetch(:delta),
        base:       options[:parents].count == 2 ? options.fetch(:base) : options[:parents].first,
        # base_delta: options[:parents].count == 2 ? options.fetch(:base_delta) : options.fetch(:delta)
      }

      new Blob.write(:commit, data)
    end

    private

    def data
      @data ||= Blob.read :commit, id
    end

  end
end