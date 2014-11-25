module Eternity
  class Session

    attr_reader :name, :index, :namespace
    
    def initialize(name)
      @name = name.to_s
      @namespace = Eternity.namespace[:session][name]
      @index = Index.new self
      @delta = Delta.new self
    end

    def head_id
      Eternity.redis.call 'GET', namespace[:head]
    end

    def head
      Commit.new head_id unless head_id.nil?
    end

    def head?
      Eternity.redis.call('EXISTS', namespace[:head]) == 1
    end

    def entries
      index.entries
    end

    def delta
      @delta.to_h
    end

    def [](section)
      index[section]
    end

    def commit(options)
      params = {
        parents: [head_id].compact, 
        index: Blob.write(:index, index.dump), 
        delta: Blob.write(:delta, delta)
      }
      
      commit_id = Commit.create options.merge(params)
      Eternity.redis.call 'SET', namespace[:head], commit_id
      @delta.destroy

      commit_id
    end

    def revert
      index.revert
      @delta.destroy
    end

    def checkout(commit_id)
      raise 'There are uncommitted changes' unless Eternity.redis.call('KEYS', namespace[:delta]['*']).empty?

      commit = Commit.new commit_id
      
      destroy
      Eternity.redis.call 'SET', namespace[:head], commit.id
      index.restore commit.index_dump
    end

    def destroy
      Eternity.redis.call 'DEL', namespace[:head]
      index.destroy
      @delta.destroy
    end

  end
end