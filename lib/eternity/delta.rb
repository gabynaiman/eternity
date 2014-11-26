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

    def empty?
      nested_namespaces.empty?
    end

    def to_h
      {}.tap do |hash|
        each_section do |section, type|
          hash[section] ||= {}
          hash[section][type] = Eternity.redis.call('SMEMBERS', namespace[section][type]).sort
        end
      end
    end

    def destroy
      each_section do |section, type|
        Eternity.redis.call 'DEL', namespace[section][type]
      end
    end

    private

    def nested_namespaces
      Eternity.redis.call 'KEYS', namespace['*']
    end

    def each_section
      nested_namespaces.each do |k|
        section, type = k.gsub(namespace[''], '').split(':')
        yield section, type
      end
    end

  end
end