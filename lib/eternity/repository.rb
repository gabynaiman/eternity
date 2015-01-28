module Eternity
  class Repository

    attr_reader :name, :id, :branches
    
    def initialize(name)
      @name = name.to_s
      @id = Eternity.keyspace[:repository][@name]
      @tracker = Tracker.new self
      @current = Restruct::Hash.new redis: Eternity.redis, id: id[:current]
      @branches = Restruct::Hash.new redis: Eternity.redis, id: id[:branches]
    end

    def [](collection)
      tracker[collection]
    end

    def changes?
      !tracker.empty?
    end

    def changes_count
      tracker.count
    end

    def delta
      tracker.flatten
    end

    def current_commit?
      current.key? :commit
    end

    def current_commit
      Commit.new current[:commit]
    end

    def current_branch
      current[:branch] || 'master'
    end

    def commit(options)
      raise 'Nothing to commit' unless changes?

      commit! message: options.fetch(:message), 
              author: options.fetch(:author)
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
      raise 'Push rejected (non fast forward)' unless current_commit.fast_forward?(Branch[current_branch])
      push!
    end

    def push!
      raise "Can't push without commit" unless current_commit?
      Branch[current_branch] = current_commit.id
    end

    def pull
      raise "Can't pull with uncommitted changes" if changes?
      raise "Branch not found: #{current_branch}" unless Branch.exists? current_branch

      target_commit = Branch[current_branch]

      if target_commit.fast_forward?(current_commit)
        patch = Patch.new current_commit, target_commit
        branches[current_branch] = target_commit.id
        current[:commit] = target_commit.id
        patch
      
      elsif current_commit.id != target_commit.id && !current_commit.fast_forward?(target_commit)
        patch = Patch.new current_commit, target_commit
        commit! author: 'System',
                message: "Merge #{target_commit.id} into #{current_commit.id}",
                parents: patch.commit_ids,
                index: write_index(patch.index_delta),
                base: patch.base_commit.id,
                base_delta: Blob.write(:delta, patch.base_delta)
        patch
      
      else
        nil
      end
    end

    def destroy
      tracker.destroy
      current.destroy
      branches.destroy
    end

    private

    attr_reader :tracker, :current

    def commit!(options)
      changes = delta
      options[:parents] ||= [current_commit.id]
      options[:delta]   ||= write_delta changes
      options[:index]   ||= write_index changes

      tracker.clear
        
      Commit.create(options).tap do |commit|
        current[:commit] = commit.id
        branches[current_branch] = commit.id
      end
    end

    def write_index(delta)
      current_commit.with_index do |index|
        index.apply delta
        index.write_blob
      end
    end

    def write_delta(delta)
      Blob.write :delta, delta
    end

  end
end