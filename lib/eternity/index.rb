module Eternity
  class Index < Restruct::NestedHash.new(IndexSection)

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

  end
end