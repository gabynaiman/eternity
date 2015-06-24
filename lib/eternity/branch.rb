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

      def names
        branches.keys
      end

      private

      def branches
        @branches ||= Restruct::Hash.new connection: Eternity.connection,
                                         id: Eternity.keyspace[:branches]
      end

    end
  end
end