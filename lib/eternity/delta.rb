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

      def merge(deltas, base_index)
        union(deltas).each_with_object({}) do |(collection, elements), hash|
          hash[collection] = {}
          elements.each do |id, changes|
            base_data = base_index[collection].include?(id) ? base_index[collection][id].data : {}
            changes.each do |change|
              current_change = change
              if hash[collection].key? id
                if hash[collection][id].nil? && change['action'] == DELETE
                  current_change = nil
                else
                  current_change = TrackFlatter.flatten [hash[collection][id], change]
                  if current_change && [INSERT, UPDATE].include?(current_change['action'])
                    current_change['data'] = ConflictResolver.resolve hash[collection][id]['data'] || base_data,
                                                                      change['data'],
                                                                      base_data
                  end
                end
              end
              hash[collection][id] = current_change
            end
            hash[collection].delete id unless hash[collection][id]
          end
          hash.delete collection if hash[collection].empty?
        end        
      end

      def revert(delta, index)
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