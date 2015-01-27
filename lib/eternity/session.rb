module Eternity
  class Session < SimpleDelegator

    def initialize(name)
      super Repository.new name
    end

    def repository
      __getobj__
    end

    def pull
      patch = repository.pull
      Synchronizer.apply patch.index_delta if patch
    end

    def self.with(name)
      @current = new name
      yield @current
    ensure
      @current = nil
    end

    def self.current
      @current
    end

  end
end