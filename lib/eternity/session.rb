module Eternity
  class Session

    attr_reader :name, :key
    
    def initialize(name)
      @name = name.to_s
      @key = Eternity.keyspace[:session][@name]
      @tracker = Tracker.new self
      @current = Restruct::Hash.new key: @key[:current]
    end

    def [](collection)
      tracker[collection]
    end

    def changes
      tracker.flatten
    end

    def changes?
      !tracker.empty?
    end

    def current_commit?
      current.key? :commit
    end

    def current_commit
      Commit.new current[:commit] if current_commit?
    end

    def current_branch
      'master'
    end

    def branches
      {}
    end

    def commit(options)
      options[:parents] ||= current_commit? ? [current_commit.id] : []
      
      Commit.create(options).tap do |commit|
        current[:commit] = commit.id
        tracker.clear
      end
    end

    private

    attr_reader :tracker, :current

  end
end