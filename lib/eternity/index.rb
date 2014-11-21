module Eternity
  class Index

    attr_reader :session, :key

    def initialize(session)
      @session = session
      @key = session.key[:index]
    end

    def entries
      sections.each_with_object({}) do |section, hash|
        hash[section] = self[section].entries
      end
    end

    def [](section)
      IndexSection.new self, section
    end

    def sections
      Eternity.redis.call('KEYS', key['*']).map do |k|
        k.gsub key[''], ''
      end
    end

    def revert
      restore session.head.index_dump
    end

    def dump
      sections.each_with_object({}) { |s,h| h[s] = self[s].dump }
    end

    def restore(dump)
      destroy
      dump.each { |s,d| self[s].restore d }
    end

    def destroy
      sections.each { |s| self[s].destroy }
    end
    
  end
end