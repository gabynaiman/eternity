module Eternity
  class Delta

    attr_reader :session, :key
    
    def initialize(session)
      @session = session
      @key = session.key[:delta]
    end

    def add(index_section, id)
      change :added, index_section, id
    end

    def update(index_section, id)
      change :updated, index_section, id
    end

    def remove(index_section, id)
      change :removed, index_section, id
    end

    def revert(index_section, id)
      each_key do |index_section, type|
        Eternity.redis.call 'SREM', key[index_section][type], id
      end
    end

    def to_h
      {}.tap do |hash|
        each_key do |index_section, type|
          hash[index_section] ||= {}
          hash[index_section][type] = Eternity.redis.call 'SMEMBERS', key[index_section][type]
        end
      end
    end

    def destroy
      each_key do |index_section, type|
        Eternity.redis.call 'DEL', key[index_section][type]
      end
    end

    private

    def each_key
      Eternity.redis.call('KEYS', key['*']).each do |k|
        index_section, type = k.gsub(key[''], '').split(':')
        yield index_section, type
      end
    end

    def change(type, index_section, id)
      Eternity.redis.call 'SADD', key[index_section][type], id
    end

  end
end