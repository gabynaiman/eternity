module Eternity
  class Tracker

    Changes = Restruct::NestedHash.new CollectionTracker
    
    extend Forwardable
    def_delegators :changes, :[], :to_h, :empty?, :destroy, :dump, :restore

    attr_reader :repository

    def initialize(repository)
      @repository = repository
      @changes = Changes.new connection: Eternity.connection, 
                             id: repository.id[:changes]
    end

    def count
      changes.inject(0) do |sum, (collection, tracker)|
        sum + tracker.count
      end
    end

    alias_method :revert, :destroy
    alias_method :clear, :destroy

    def flatten
      changes.each_with_object({}) do |(collection, tracker), hash|
        collection_changes = tracker.flatten
        hash[collection] = collection_changes unless collection_changes.empty?
      end
    end

    private

    attr_reader :changes
    
  end
end