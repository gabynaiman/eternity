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
    
    def self.create(options)
      data = {
        time:       Time.now.strftime('%Y-%m-%dT%H:%M:%S%z'),
        author:     options.fetch(:author),
        message:    options.fetch(:message),
        parents:    options.fetch(:parents),
        # base:       options[:parents].count == 2 ? options.fetch(:base) : options[:parents].first,
        # index:      options.fetch(:index),
        # delta:      options.fetch(:delta),
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