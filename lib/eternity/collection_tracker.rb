module Eternity
  class CollectionTracker
    
    Changes = Restruct::NestedHash.new ObjectTracker

    extend Forwardable
    def_delegators :changes, :to_h, :to_primitive, :count, :[], :destroy

    def initialize(options)
      @changes = Changes.new options
    end

    def insert(id, data)
      changes[id].insert data
    end

    def update(id, data)
      changes[id].update data
    end

    def delete(id)
      changes[id].delete
    end

    def revert(id)
      changes[id].revert
    end

    def revert_all
      locker.lock! :revert_all do
        changes.destroy
      end
    end

    def flatten
      changes.each_with_object({}) do |(id, tracker), hash|
        change = tracker.flatten
        hash[id] = change if change
      end
    end

    private

    attr_reader :changes

    def locker
      Eternity.locker_for repository_name
    end

    def repository_name
      changes.id.sections.reverse[2]
    end

  end
end