module Eternity
  class ObjectTracker

    INSERT = 'insert'.freeze
    UPDATE = 'update'.freeze
    DELETE = 'delete'.freeze

    def initialize(options)
      @changes = Restruct::MarshalArray.new options
    end

    def insert(data)
      track INSERT, data
    end

    def update(data)
      track UPDATE, data
    end

    def delete
      track DELETE
    end

    def revert
      changes.destroy
    end

    def flatten
      change = send "flatten_#{changes.first['action']}_#{changes.last['action']}"
      expand change if change
    end

    def to_a
      changes.to_a
    end
    alias_method :to_primitive, :to_a

    private

    attr_reader :changes

    def track(action, data=nil)
      change = {'action' => action}
      change['blob'] = Blob.write(:data, data) if data
      changes << change
    end

    def expand(change)
      change.tap do |ch|
        sha1 = ch.delete 'blob'
        ch['data'] = Blob.read(:data, sha1) if sha1
      end
    end

    def flatten_insert_insert
      changes.last
    end

    def flatten_insert_update
      {'action' => INSERT, 'blob' => changes.last['blob']}
    end

    def flatten_insert_delete
      nil
    end

    def flatten_update_insert
      {'action' => UPDATE, 'blob' => changes.last['blob']}
    end

    def flatten_update_update
      changes.last
    end

    def flatten_update_delete
      changes.last
    end

    def flatten_delete_insert
      {'action' => UPDATE, 'blob' => changes.last['blob']}
    end

    def flatten_delete_update
      {'action' => UPDATE, 'blob' => changes.last['blob']}
    end

    def flatten_delete_delete
      changes.last
    end

  end
end