module Eternity
  class Commit

    attr_reader :id

    def initialize(id)
      @id = id
    end

    def time
      Time.parse(data['time']) if data['time']
    end

    def author
      data['author']
    end

    def message
      data['message']
    end

    def parent_ids
      data['parents'] || [nil]
    end

    def parents
      parent_ids.map { |id| Commit.new id }
    end

    def with_index
      index = data['index'] ? Index.read_blob(data['index']) : Index.new
      yield index
    ensure
      index.destroy if index
    end

    def delta
      data['delta'] ? Blob.read(:delta, data['delta']) : {}
    end

    def base
      Commit.new data['base']
    end

    def base_delta
      data['base_delta'] ? Blob.read(:delta, data['base_delta']) : {}
    end

    def fast_forward?(commit)
      return commit.id.nil? if first?
      parent_ids.any? { |id| id == commit.id } || parents.map { |c| c.fast_forward?(commit) }.inject(:|)
    end

    def base_history_at(commit)
      return [] unless commit
      history = [base]
      history += base.base_history_at commit unless base.id == commit.id
      raise "History not include commit #{commit.id}" unless history.map(&:id).include? commit.id
      history
    end

    def first?
      parent_ids.compact.empty?
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
        base_delta: options[:parents].count == 2 ? options.fetch(:base_delta) : options.fetch(:delta)
      }

      new Blob.write(:commit, data)
    end

    def self.base_of(commit_1, commit_2)
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

    private

    def data
      @data ||= id ? Blob.read(:commit, id) : {}
    end

  end
end