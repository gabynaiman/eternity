module Eternity
  class Index < Restruct::NestedHash.new(CollectionIndex)

    attr_reader :session

    def initialize(session=nil)
      @session = session || Session.new
      super key: @session.key[:index]
    end

    def revert
      if session.current_commit?
        restore session.current_commit.index_dump
      else
        destroy
      end
    end

    def entries
      each_with_object({}) do |(name, collection_index), hash|
        hash[name] = collection_index.entries
      end
    end

  end
end