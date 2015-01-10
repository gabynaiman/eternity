module Eternity
  class Session

    attr_reader :name, :key, :branches
    
    def initialize(name)
      @name = name.to_s
      @key = Eternity.keyspace[:session][@name]
      @tracker = Tracker.new self
      @current = Restruct::Hash.new redis: Eternity.redis,
                                    key: key[:current]
      @branches = Restruct::Hash.new redis: Eternity.redis,
                                     key: key[:branches]
    end

    def [](collection)
      tracker[collection]
    end

    def changes?
      !tracker.empty?
    end

    def delta
      tracker.flatten
    end

    def current_commit?
      current.key? :commit
    end

    def current_commit
      Commit.new current[:commit] if current_commit?
    end

    def current_branch
      current[:branch] || 'master'
    end

    def with_index
      index = current_commit? ? current_commit.index : Index.new
      yield index
    ensure
      index.destroy
    end

    def commit(options)
      raise 'Nothing to commit' unless changes?
      
      options[:parents] ||= current_commit? ? [current_commit.id] : []
      options[:delta] = Blob.write :delta, delta
      options[:index] = with_index do |index|
        index.apply delta
        index.write_blob
      end
      
      Commit.create(options).tap do |commit|
        current[:commit] = commit.id
        branches[current_branch] = commit.id
        tracker.clear
      end
    end

    def branch(name)
      raise "Can't branch without commit" unless current_commit?
      raise "Can't branch with uncommitted changes" if changes?

      branches[name] = current_commit.id
    end

    def checkout(branch)
      raise "Can't checkout with uncommitted changes" if changes?

      commit_id =
        if branches.key? branch
          branches[branch]
        elsif Branch.exists?(branch)
          Branch[branch].id
        else
          raise "Invalid branch #{branch}"
        end

      current[:commit] = commit_id
      current[:branch] = branch
      branches[branch] = commit_id
    end

    def push
      raise 'Push rejected (non fast forward)' if current_commit? && !current_commit.fast_forward?(Branch[current_branch])
      push!
    end

    def push!
      raise "Can't push without commit" unless current_commit?
      Branch[current_branch] = current_commit.id
    end

    private

    attr_reader :tracker, :current

  end
end