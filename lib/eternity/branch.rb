module Eternity
  class Branch

    def self.[](name)
      Commit.new branches[name] if exists? name
    end

    def self.[]=(name, commit_id)
      branches[name] = commit_id
    end

    def self.exists?(name)
      branches.key? name
    end

    def self.branches
      @branches ||= Restruct::Hash.new redis: Eternity.redis,
                                       key: Eternity.keyspace[:branches]
    end
    private_class_method :branches
    
  end
end