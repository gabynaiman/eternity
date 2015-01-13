module Eternity
  class TrackFlatter
    class << self

      def flatten(changes)
        send "flatten_#{changes.first['action']}_#{changes.last['action']}", changes
      end

      private

      def flatten_insert_insert(changes)
        expand changes.last
      end

      def flatten_insert_update(changes)
        {'action' => INSERT, 'data' => expand(changes.last)['data']}
      end

      def flatten_insert_delete(changes)
        nil
      end

      def flatten_update_insert(changes)
        {'action' => UPDATE, 'data' => expand(changes.last)['data']}
      end

      def flatten_update_update(changes)
        expand changes.last
      end

      def flatten_update_delete(changes)
        expand changes.last
      end

      def flatten_delete_insert(changes)
        {'action' => UPDATE, 'data' => expand(changes.last)['data']}
      end

      def flatten_delete_update(changes)
        {'action' => UPDATE, 'data' => expand(changes.last)['data']}
      end

      def flatten_delete_delete(changes)
        expand changes.last
      end

      def expand(change)
        return change if change.key? 'data'
        change.tap do |ch|
          sha1 = ch.delete 'blob'
          ch['data'] = Blob.read(:data, sha1) if sha1
        end
      end
   
    end 
  end
end