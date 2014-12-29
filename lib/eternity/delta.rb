module Eternity
  class Delta < Restruct::NestedHash.new(CollectionDelta)

    attr_reader :session

    def initialize(session=nil)
      @session = session || Session.new
      super key: @session.key[:delta]
    end

    def self.merge(*deltas)
      delta = Hash.new do |h,k| 
        h[k] = {
          ADDED   => [],
          UPDATED => [],
          REMOVED => []
        }
      end

      base_added   = Hash.new { |h,k| h[k] = [] }
      base_removed = Hash.new { |h,k| h[k] = [] }

      deltas.flatten.each do |d|
        d.each_key do |collection|
          current = {
            ADDED   => d[collection][ADDED]   || [],
            UPDATED => d[collection][UPDATED] || [],
            REMOVED => d[collection][REMOVED] || []
          }

          added   = current[ADDED]   - base_removed[collection]
          updated = current[UPDATED] - base_added[collection]
          removed = current[REMOVED] - base_added[collection]

          base_added[collection]   += added
          base_removed[collection] += removed

          delta[collection][ADDED]   += added
          delta[collection][UPDATED] += updated + (current[ADDED] & base_removed[collection])
          delta[collection][REMOVED] += removed

          delta[collection][ADDED]   -= current[REMOVED]
          delta[collection][UPDATED] -= current[REMOVED]
          delta[collection][REMOVED] -= current[ADDED]
        end
      end

      compact delta
    end

    def self.compact(delta)
      delta.each_key do |collection|
        delta[collection].each_key do |type|
          delta[collection][type].uniq!
          delta[collection].delete type if delta[collection][type].empty?
        end
        delta.delete collection if delta[collection].empty?
      end
    end

  end
end