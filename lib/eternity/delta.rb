module Eternity
  class Delta < Restruct::NestedHash.new(CollectionDelta)

    attr_reader :session

    def initialize(session=nil)
      @session = session || Session.new
      super key: @session.key[:delta]
    end

    def self.merge(*args)
      deltas = args.flatten
      return deltas.first if deltas.count == 1

      delta = Hash.new do |h,k| 
        h[k] = {
          ADDED   => [],
          UPDATED => [],
          REMOVED => []
        }
      end

      base_added   = Hash.new { |h,k| h[k] = [] }
      base_removed = Hash.new { |h,k| h[k] = [] }

      deltas.each do |current|
        current.each_key do |collection|
          EVENTS.each { |e| current[collection][e] ||= [] }

          added   = current[collection][ADDED]   - base_removed[collection]
          updated = current[collection][UPDATED] - base_added[collection]
          removed = current[collection][REMOVED] - base_added[collection]

          base_added[collection]   += added
          base_removed[collection] += removed

          delta[collection][ADDED]   += added
          delta[collection][UPDATED] += updated + (current[collection][ADDED] & base_removed[collection])
          delta[collection][REMOVED] += removed

          delta[collection][ADDED]   -= current[collection][REMOVED]
          delta[collection][UPDATED] -= current[collection][REMOVED]
          delta[collection][REMOVED] -= (current[collection][ADDED] + current[collection][UPDATED])
        end
      end

      compact delta
    end

    private

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