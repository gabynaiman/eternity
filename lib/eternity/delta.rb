module Eternity
  class Delta

    attr_reader :session, :namespace
    
    def initialize(session)
      @session = session
      @namespace = session.namespace[:delta]
    end

    def [](section)
      DeltaSection.new self, section
    end

    def to_h
      {}.tap do |hash|
        each_namespace do |section, type|
          hash[section] ||= {}
          hash[section][type] = Eternity.redis.call 'SMEMBERS', namespace[section][type]
        end
      end
    end

    def destroy
      each_namespace do |section, type|
        Eternity.redis.call 'DEL', namespace[section][type]
      end
    end

    private

    def each_namespace
      Eternity.redis.call('KEYS', namespace['*']).each do |k|
        section, type = k.gsub(namespace[''], '').split(':')
        yield section, type
      end
    end

  end
end