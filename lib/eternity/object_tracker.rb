module Eternity
  class ObjectTracker

    extend Forwardable
    def_delegators :changes, :to_a, :to_primitive, :count, :each, :destroy

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
      locker.lock :revert do
        changes.destroy
      end
    end

    def flatten
      TrackFlatter.flatten changes
    end

    private

    attr_reader :changes

    def track(action, data=nil)
      locker.lock action do
        change = {'action' => action}
        change['blob'] = Blob.write(:data, data) if data

        Eternity.logger.debug(self.class) { "#{changes.id} - #{change} - #{data}" }
        
        changes << change
      end
    end

    def locker
      Locky.new repository_name, Eternity.locker_adapter
    end

    def repository_name
      changes.id.sections.reverse[3]
    end

  end
end