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

    def empty?
      tracker.empty? && current.empty? && branches.empty?
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

    def delta=(delta)
      tracker.clear
      delta.each do |collection, changes|
        changes.each do |id, change|
          args = [id, change['data']].compact
          self[collection].send(change['action'], *args)
        end
      end
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
              author:  options.fetch(:author),
              time:    options.fetch(:time) { Time.now }
    end

    def branch(name)
      raise "Can't branch without commit" unless current_commit?
      raise "Can't branch with uncommitted changes" if changes?

      branches[name] = current_commit.id
    end

    def checkout(options)
      raise "Can't checkout with uncommitted changes" if changes?

      branch = options.fetch(:branch) { current_branch }
      
      commit_id = options.fetch(:commit) do
        if branches.key? branch
          branches[branch]
        elsif Branch.exists?(branch)
          Branch[branch].id
        else
          raise "Invalid branch #{branch}"
        end
      end

      original_commit = current_commit

      if commit_id
        raise "Invalid commit #{commit_id}" unless Commit.exists? commit_id
        current[:commit] = commit_id
        branches[branch] = commit_id
      else
        current.delete :commit
        branches.delete branch
      end

      current[:branch] = branch

      Patch.new original_commit, current_commit unless original_commit.id == current_commit.id
    end

    def push
      raise 'Push rejected (non fast forward)' if current_commit.id != Branch[current_branch].id && !current_commit.fast_forward?(Branch[current_branch])
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
        commit! message:    "Merge #{target_commit.short_id} into #{current_commit.short_id}",
                author:     'System',
                parents:    patch.commit_ids,
                index:      write_index(patch.index_delta),
                base:       patch.base_commit.id,
                base_delta: Blob.write(:delta, patch.base_delta)
        patch
      
      else
        nil
      end
    end

    def revert
      reverted_delta.tap { tracker.revert }
    end

    def log
      current_commit? ? ([current_commit] + current_commit.history) : []
    end

    def destroy
      tracker.destroy
      current.destroy
      branches.destroy
    end

    def to_h
      {
        'current' => current.to_h,
        'branches' => branches.to_h,
        'tracker' => tracker.to_h
      }
    end

    private

    attr_reader :tracker, :current

    def commit!(options)
      changes = delta
      options[:parents] ||= [current_commit.id]
      options[:delta]   ||= write_delta changes
      options[:index]   ||= write_index changes

      Commit.create(options).tap do |commit|
        current[:commit] = commit.id
        branches[current_branch] = commit.id
        tracker.clear
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

    def reverted_delta
      current_commit.with_index do |index|
        delta.each_with_object({}) do |(collection, changes), hash|
          hash[collection] = {}
          changes.each do |id, change|
            hash[collection][id] = 
              case change['action']
                when INSERT then {'action' => DELETE}
                when UPDATE then {'action' => UPDATE, 'data' => index[collection][id].data}
                when DELETE then {'action' => INSERT, 'data' => index[collection][id].data}
              end
          end
        end
      end
    end

  end
end