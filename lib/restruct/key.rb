module Restruct
  class Key < String
    attr_reader :separator

    def initialize(key, separator=nil)
      @separator = separator || Restruct.key_separator
      super key.to_s
    end

    def [](key)
      Key.new "#{to_s}#{separator}#{key}"
    end

    def sections
      split(separator).map { |s| Key.new s }
    end

    def self.join(keys, separator=nil)
      new keys.join(separator || Restruct.key_separator)
    end
  end
end