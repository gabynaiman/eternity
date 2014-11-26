module Eternity
  class Index

    attr_reader :session, :namespace

    def initialize(session)
      @session = session
      @namespace = session.namespace[:index]
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
      Eternity.redis.call('KEYS', namespace['*']).map do |k|
        k.gsub namespace[''], ''
      end
    end

    def revert
      if session.current_commit?
        restore session.current_commit.index_dump
      else
        destroy
      end
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