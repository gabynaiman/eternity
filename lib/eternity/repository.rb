module Eternity
  class Repository

    attr_reader :name, :id, :branches
    
    def initialize(name, options={})
      @name = name.to_s
      @id = Eternity.keyspace[:repository][@name]
      @tracker = Tracker.new self
      @current = Restruct::Hash.new redis: Eternity.redis, id: id[:current]
      @branches = Restruct::Hash.new redis: Eternity.redis, id: id[:branches]
      @locker = Locky.new @name, Eternity.locker_storage
      @default_branch = options.fetch(:default_branch) { 'master' }.to_s
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
      current[:branch] || @default_branch
    end

    def commit(options)
      raise 'Nothing to commit' unless changes?

      locker.lock! :commit do
        commit! message: options.fetch(:message), 
                author:  options.fetch(:author)
      end
    end

    def branch(name)
      raise "Can't branch without commit" unless current_commit?
      raise "Can't branch with uncommitted changes" if changes?

      branches[name] = current_commit.id
    end

    def checkout(options)
      raise "Can't checkout with uncommitted changes" if changes?

      locker.lock! :checkout do
        original_commit = current_commit

        commit_id, branch = extract_commit_and_branch options

        if commit_id
          raise "Invalid commit #{commit_id}" unless Commit.exists? commit_id
          current[:commit] = commit_id
          branches[branch] = commit_id
        else
          current.delete :commit
          branches.delete branch
        end

        current[:branch] = branch

        Patch.diff(original_commit, current_commit).delta
      end
    end

    def merge(options)
      raise "Can't merge with uncommitted changes" if changes?

      commit_id = extract_commit options

      raise "Invalid commit #{commit_id}" unless Commit.exists? commit_id

      merge! Commit.new(commit_id)
    end

    def push
      raise 'Push rejected (non fast forward)' if current_commit != Branch[current_branch] && !current_commit.fast_forward?(Branch[current_branch])
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

      if current_commit == target_commit || current_commit.fast_forward?(target_commit)
        {}
      elsif target_commit.fast_forward?(current_commit)
        checkout commit: target_commit.id
      else 
        merge! target_commit
      end
    end

    def revert
      locker.lock! :revert do
        current_commit.with_index do |index|
          Delta.revert(delta, index).tap { tracker.revert }
        end
      end
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
        'delta' => delta
      }
    end
    alias_method :dump, :to_h

    def restore(dump)
      current.merge! dump['current']
      branches.merge! dump['branches']
      self.delta = dump['delta']
    end

    private

    attr_reader :tracker, :current, :locker

    def commit!(options)
      changes = delta
      options[:parents] ||= [current_commit.id]
      options[:delta]   ||= write_delta changes
      options[:index]   ||= write_index changes

      Commit.create(options).tap do |commit|
        current[:commit] = commit.id
        current[:branch] = current_branch
        branches[current_branch] = commit.id
        tracker.clear
      end
    end

    def merge!(target_commit)
      locker.lock! :merge do
        patch = Patch.merge current_commit, target_commit

        raise 'Already merged' if patch.merged?

        commit! message: "Merge #{target_commit.short_id} into #{current_commit.short_id} (#{name})",
                author:  'System',
                parents: [current_commit.id, target_commit.id],
                index:   write_index(patch.delta),
                base:    patch.base_commit.id

        patch.delta
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

    def extract_commit(options)
      extract_commit_and_branch(options).first
    end

    def extract_commit_and_branch(options)
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

      [commit_id, branch]
    end

  end
end