module Eternity
  class Branch

    attr_reader :name

    def initialize(name)
      @name = name
    end

    def commit_id
      self.class.all[name]
    end

    def commit_id=(id)
      self.class.all[name] = id
    end

    def commit
      Commit.new commit_id
    end

    def self.exists?(name)
      all.key? name
    end

    private

    def self.all
      @all ||= Restruct::Hash.new key: Eternity.keyspace[:branches]
    end

  end
end