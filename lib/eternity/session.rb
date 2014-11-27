module Eternity
  class Session

    attr_reader :name, :index, :namespace
    
    def initialize(name)
      @name = name.to_s
      @namespace = Eternity.namespace[:session][name]
      @index = Index.new self
      @delta = Delta.new self
    end

    def entries
      index.entries
    end

    def delta
      @delta.to_h
    end

    def delta?
      !@delta.empty?
    end

    def [](section)
      index[section]
    end

    def commit(options)
      raise 'Nothing to commit' if @delta.empty?

      params = {
        parents: [current_commit_id].compact,
        index: Blob.write(:index, index.dump),
        delta: Blob.write(:delta, @delta.to_h)
      }
      
      commit_id = Commit.create options.merge(params)

      Eternity.redis.call 'SET', namespace[:current_commit], commit_id
      Eternity.redis.call 'HSET', namespace[:branches], current_branch, commit_id

      @delta.destroy

      commit_id
    end

    def revert
      @delta.destroy
      index.revert
    end

    def current_commit_id
      Eternity.redis.call 'GET', namespace[:current_commit]
    end

    def current_commit
      Commit.new current_commit_id if current_commit?
    end

    def current_commit?
      Eternity.redis.call('EXISTS', namespace[:current_commit]) == 1
    end

    def current_branch
      Eternity.redis.call('GET', namespace[:current_branch]) || 'master'
    end

    def branches
      Hash[Eternity.redis.call('HGETALL', namespace[:branches]).each_slice(2).to_a]
    end

    def branch(name)
      raise 'Cant branch without commit' unless current_commit?
      raise 'Cant branch with uncommitted changes' if delta?

      Eternity.redis.call 'HSET', namespace[:branches], name, current_commit_id
    end

    def checkout(branch)
      raise 'Cant checkout with uncommitted changes' if delta?

      commit_id =
        if branches.key?(branch.to_s)
          branches[branch.to_s]
        elsif Branch.exists?(branch)
          Branch.new(branch).commit_id
        else
          raise "Invalid branch #{branch}"
        end

      Eternity.redis.call 'SET', namespace[:current_commit], commit_id
      Eternity.redis.call 'SET', namespace[:current_branch], branch
      Eternity.redis.call 'HSET', namespace[:branches], branch, commit_id
      
      @delta.destroy
      index.destroy
      index.restore Commit.new(commit_id).index_dump
    end

    def destroy
      Eternity.redis.call 'DEL', namespace[:current_commit]
      Eternity.redis.call 'DEL', namespace[:current_branch]
      Eternity.redis.call 'DEL', namespace[:branches]

      @delta.destroy
      index.destroy
    end

  end
end