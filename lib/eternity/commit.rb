module Eternity
  class Commit

    attr_reader :id

    def initialize(id)
      @id = id
    end

    def short_id
      id ? id[0,7] : nil
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

    def history_times
      data['history_times'] ? Blob.read(:history_times, data['history_times']) : {}
    end

    def history
      history_times.sort_by { |id, time| time }
                   .map { |id, time| Commit.new id }
                   .reverse
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
      raise 'Author must be present' if options[:author].to_s.strip.empty?
      raise 'Message must be present' if options[:message].to_s.strip.empty?

      history_times = options[:parents].compact.each_with_object({}) do |id, hash|
        commit = Commit.new id
        hash.merge! id => commit.time
        hash.merge! commit.history_times
      end

      data = {
        time:          options.fetch(:time) { Time.now },
        author:        options.fetch(:author),
        message:       options.fetch(:message),
        parents:       options.fetch(:parents),
        index:         options.fetch(:index),
        delta:         options.fetch(:delta),
        base:          options[:parents].count == 2 ? options.fetch(:base) : options[:parents].first,
        base_delta:    options[:parents].count == 2 ? options.fetch(:base_delta) : options.fetch(:delta),
        history_times: Blob.write(:history_times, history_times)
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

    def self.exists?(id)
      Blob.read :commit, id
      true
    rescue
      false
    end

    private

    def data
      @data ||= id ? Blob.read(:commit, id) : {}
    end

  end
end