module Eternity
  class Delta < Restruct::NestedHash.new(DeltaSection)

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
        d.each_key do |section|
          current = {
            ADDED   => d[section][ADDED]   || [],
            UPDATED => d[section][UPDATED] || [],
            REMOVED => d[section][REMOVED] || []
          }

          added   = current[ADDED]   - base_removed[section]
          updated = current[UPDATED] - base_added[section]
          removed = current[REMOVED] - base_added[section]

          base_added[section]   += added
          base_removed[section] += removed

          delta[section][ADDED]   += added
          delta[section][UPDATED] += updated + (current[ADDED] & base_removed[section])
          delta[section][REMOVED] += removed

          delta[section][ADDED]   -= current[REMOVED]
          delta[section][UPDATED] -= current[REMOVED]
          delta[section][REMOVED] -= current[ADDED]
        end
      end

      compact delta
    end

    def self.compact(delta)
      delta.each_key do |section|
        delta[section].each_key do |type|
          delta[section][type].uniq!
          delta[section].delete type if delta[section][type].empty?
        end
        delta.delete section if delta[section].empty?
      end
    end

  end
end