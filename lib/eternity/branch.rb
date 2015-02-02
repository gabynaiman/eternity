module Eternity
  class Branch
    class << self

      def [](name)
        Commit.new branches[name]
      end

      def []=(name, commit_id)
        branches[name] = commit_id
      end

      def exists?(name)
        branches.key? name
      end

      def delete(name)
        branches.delete name
      end

      private

      def branches
        @branches ||= Restruct::Hash.new redis: Eternity.redis,
                                         id: Eternity.keyspace[:branches]
      end

    end
  end
end