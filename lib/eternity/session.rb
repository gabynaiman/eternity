module Eternity
  class Session

    attr_reader :name, :index, :key, :branches
    
    def initialize(name=nil)
      @name = name.to_s || Restruct.generate_key
      @key = Eternity.keyspace[:session][@name]
      @index = Index.new self
      @delta = Delta.new self
      @current = Restruct::Hash.new key: key[:current]
      @branches = Restruct::Hash.new key: key[:branches]
    end

    def current_commit_id
      current[:commit]
    end

    def current_commit
      Commit.new current_commit_id if current_commit?
    end

    def current_commit?
      current.key? :commit
    end

    def current_branch
      current[:branch] || 'master'
    end

    def entries
      index.to_h
    end

    def changes
      delta.to_h
    end

    def changes?
      !delta.empty?
    end

    def [](section)
      index[section]
    end

    def commit(options)
      commit! message: options.fetch(:message), 
              author: options.fetch(:author)
    end

    def revert
      delta.destroy
      index.revert
    end

    def branch(name)
      raise 'Cant branch without commit' unless current_commit?
      raise 'Cant branch with uncommitted changes' if changes?

      branches[name] = current_commit_id
    end

    def checkout(branch)
      raise 'Cant checkout with uncommitted changes' if changes?

      commit_id =
        if branches.key? branch
          branches[branch]
        elsif Branch.exists?(branch)
          Branch.new(branch).commit_id
        else
          raise "Invalid branch #{branch}"
        end

      current[:commit] = commit_id
      current[:branch] = branch
      branches[branch] = commit_id
      
      delta.destroy
      index.restore Commit.new(commit_id).index_dump
    end

    def push
      raise 'Cant push without commit' unless current_commit?
      raise 'Push rejected. Non fast forward' unless current_commit.fast_forward?(Branch.new(current_branch).commit_id)
      
      push!
    end

    def push!
      Branch.new(current_branch).commit_id = current_commit_id
    end

    def pull
      raise 'Cant pull with uncommitted changes' if changes?
      raise "Branch not found: #{current_branch}" unless Branch.exists? current_branch
      
      branch = Branch.new current_branch

      if branch.commit.fast_forward? current_commit_id
        branches[current_branch] = branch.commit_id
        checkout current_branch
      else
        patch = Patch.new current_commit, branch.commit
        patch.apply_to index

        commit! author: 'System',
                message: "Merge #{branch.commit_id} into #{current_commit_id}",
                parents: patch.commit_ids,
                delta: Blob.write(:delta, {}),
                base: patch.base.id,
                base_delta: Blob.write(:delta, patch.base_delta)
      end
    end

    def destroy
      current.destroy
      branches.destroy
      delta.destroy
      index.destroy
    end

    def restore(commit)
      delta.destroy
      index.restore commit.index_dump
    end

    private

    attr_reader :delta, :current

    def commit!(options)
      raise 'Nothing to commit' unless changes?

      options[:index] = Blob.write :index, index.dump
      options[:delta] ||= Blob.write :delta, delta.to_h
      options[:parents] ||= [current_commit_id].compact
      
      Commit.create(options).tap do |commit_id|
        current[:commit] = commit_id
        branches[current_branch] = commit_id
        delta.destroy
      end
    end

  end
end