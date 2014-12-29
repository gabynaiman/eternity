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

    def base_id
      @data['base']
    end

    def base
      Commit.new base_id if base_id
    end

    def index_id
      @data['index']
    end

    def index_dump
      Blob.read :index, index_id
    end

    def with_index
      index = Index.new
      index.restore index_dump
      yield index
    ensure
      index.destroy
    end

    def delta_id
      @data['delta']
    end

    def delta
      Blob.read :delta, delta_id
    end

    def base_delta_id
      @data['base_delta']
    end

    def base_delta
      Blob.read :delta, base_delta_id
    end

    def fast_forward?(commit_id)
      base_id == commit_id || 
      (base_id && base.fast_forward?(commit_id))
    end

    def base_history_at(commit_id)
      history = [base]
      history += base.base_history_at commit_id unless base_id == commit_id
      raise "History not include commit #{commit_id}" unless history.map(&:id).include? commit_id
      history
    end

    def delta_base_from(commit)
      history = [self] + self.base_history_at(commit.id)[0..-2]
      Delta.merge history.reverse.map(&:base_delta)
    end

    def self.create(data)
      params = {
        time:       Time.now.strftime('%Y-%m-%dT%H:%M:%S%z'),
        author:     data.fetch(:author),
        message:    data.fetch(:message),
        parents:    data.fetch(:parents),
        base:       data[:parents].count == 2 ? data.fetch(:base) : data[:parents].first,
        index:      data.fetch(:index),
        delta:      data.fetch(:delta),
        base_delta: data[:parents].count == 2 ? data.fetch(:base_delta) : data.fetch(:delta)
      }

      Blob.write :commit, params
    end

    def self.find_base(commit_1, commit_2)
      history_1 = []
      history_2 = []

      base_1 = commit_1
      base_2 = commit_2

      while (history_1 & history_2).empty?
        base_1 = base_1.base if base_1
        base_2 = base_2.base if base_2
        
        history_1 << base_1.id if base_1
        history_2 << base_2.id if base_2
      end

      Commit.new (history_1 & history_2).first
    end

  end
end