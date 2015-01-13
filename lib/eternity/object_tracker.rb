module Eternity
  class ObjectTracker

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
      TrackFlatter.flatten changes
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

  end
end