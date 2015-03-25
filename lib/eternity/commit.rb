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
      Time.parse data['time'] if data['time']
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

    def history_ids
      if data['history']
        Blob.read :history, data['history']
      else
        # Backward compatibility
        if parent_ids.count == 2
          current_history_ids = [parent_ids[0]] + Commit.new(parent_ids[0]).history_ids
          target_history_ids = [parent_ids[1]] + Commit.new(parent_ids[1]).history_ids
          current_history_ids - target_history_ids + target_history_ids
        else
          parent_id = parent_ids[0]
          parent_id ? [parent_id] + Commit.new(parent_id).history_ids : []
        end
      end
    end

    def history
      history_ids.map { |id| Commit.new id }
    end

    def fast_forward?(commit)
      return true if commit.nil?
      history_ids.include? commit.id
    end

    def first?
      parent_ids.compact.empty?
    end

    def merge?
      parent_ids.count == 2
    end

    def nil?
      id.nil?
    end

    def ==(commit)
      commit.class == self.class && 
      commit.id == id
    end
    alias_method :eql?, :==

    def hash
      id.hash
    end

    def to_s
      "#{time} - #{short_id} - #{author}: #{message}"
    end

    def self.create(options)
      raise 'Author must be present' if options[:author].to_s.strip.empty?
      raise 'Message must be present' if options[:message].to_s.strip.empty?

      # TODO: Move to Repository and Patch
      history =
        if options[:parents].count == 2
          current_history_ids = [options[:parents][0]] + Commit.new(options[:parents][0]).history_ids
          target_history_ids = [options[:parents][1]] + Commit.new(options[:parents][1]).history_ids
          current_history_ids - target_history_ids + target_history_ids
        else
          parent_id = options[:parents][0]
          parent_id ? [parent_id] + Commit.new(parent_id).history_ids : []
        end

      data = {
        time:          Time.now,
        author:        options.fetch(:author),
        message:       options.fetch(:message),
        parents:       options.fetch(:parents),
        index:         options.fetch(:index),
        delta:         options.fetch(:delta),
        base:          options[:parents].count == 2 ? options.fetch(:base) : options[:parents].first,
        history:       Blob.write(:history, history)
      }

      new Blob.write(:commit, data)
    end

    def self.base_of(commit_1, commit_2)
      history_1 = [commit_1.id]
      history_2 = [commit_2.id]

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