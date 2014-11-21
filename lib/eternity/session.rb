module Eternity
  class Session

    attr_reader :name, :index, :key
    
    def initialize(name)
      @name = name.to_s
      @key = Eternity.namespace[:session][name]
      @index = Index.new self
      @delta = Delta.new self
    end

    def head_id
      Eternity.redis.call 'GET', key[:head]
    end

    def head
      Commit.new head_id unless head_id.nil?
    end

    def delta
      @delta.to_h
    end

    def [](section)
      index[section]
    end

    def commit(options)
      commit_id = Commit.create options.merge(parents: [head_id].compact, index: write_index, delta: write_delta)
      Eternity.redis.call 'SET', key[:head], commit_id
      @delta.destroy
    end

    def revert
      index.revert
      @delta.destroy
    end

    def checkout(commit_id)
      raise 'There are uncommitted changes' unless Eternity.redis.call('KEYS', key[:delta]['*']).empty?

      commit = Commit.new commit_id
      
      destroy
      Eternity.redis.call 'SET', key[:head], commit.id
      index.restore commit.index_dump
    end

    def destroy
      Eternity.redis.call 'DEL', key[:head]
      index.destroy
      @delta.destroy
    end

    private

    def write_index
      Blob.write :index, index.dump
    end

    def write_delta
      Blob.write :delta, delta.to_h
    end

  end
end