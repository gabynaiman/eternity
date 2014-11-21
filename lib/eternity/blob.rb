module Eternity
  class Blob
  
    def self.write(type, data)
      serialization = MessagePack.pack data
      sha1 = Digest::SHA1.hexdigest serialization
      Eternity.redis.call 'SET', Eternity.namespace[:blob][type][sha1], serialization
      sha1
    end

    def self.read(type, sha1)
      serialization = Eternity.redis.call 'GET', Eternity.namespace[:blob][type][sha1]
      raise "Blob not found. #{type.capitalize}: #{sha1}" if serialization.nil?
      MessagePack.unpack serialization
    end
  
  end
end