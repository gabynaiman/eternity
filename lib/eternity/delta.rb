module Eternity
  class Delta
    class << self

      def union(deltas)
        deltas.each_with_object({}) do |delta, hash|
          delta.each do |collection, elements|
            hash[collection] ||= {}
            elements.each do |id, change|
              hash[collection][id] ||= []
              hash[collection][id] << change
            end
          end
        end
      end

      def merge(deltas)
        union(deltas).each_with_object({}) do |(collection, elements), hash|
          hash[collection] = {}
          elements.each do |id, changes|
            change = TrackFlatter.flatten changes
            hash[collection][id] = TrackFlatter.flatten changes if change
          end
        end
      end

      def revert(delta, commit)
        commit.with_index do |index|
          delta.each_with_object({}) do |(collection, changes), hash|
            hash[collection] = {}
            changes.each do |id, change|
              hash[collection][id] = 
                case change['action']
                  when INSERT then {'action' => DELETE}
                  when UPDATE then {'action' => UPDATE, 'data' => index[collection][id].data}
                  when DELETE then {'action' => INSERT, 'data' => index[collection][id].data}
                end
            end
          end
        end
      end

    end
  end
end