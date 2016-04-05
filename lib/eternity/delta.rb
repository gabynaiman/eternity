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
            current_change = TrackFlatter.flatten changes
            if current_change 
              if current_change['action'] == UPDATE
                base_data = base_index[collection].include?(id) ? base_index[collection][id].data : {}
                current_change['data'] = changes.select { |c| c['data'] }
                                                .inject(base_data) { |d,c| ConflictResolver.resolve d, c['data'], base_data }
              end
              hash[collection][id] = current_change
            end
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