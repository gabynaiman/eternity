module Eternity
  class Tracker

    Changes = Restruct::NestedHash.new CollectionTracker
    
    extend Forwardable
    def_delegators :changes, :[], :to_h, :empty?

    attr_reader :session

    def initialize(session)
      @session = session
      @changes = Changes.new redis: Eternity.redis, 
                             key: session.key[:changes]
    end

    def revert
      changes.each { |_,t| t.revert_all }
    end
    alias_method :clear, :revert

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