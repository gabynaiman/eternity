module Eternity
  class Blob
  
    def self.write(type, data)
      serialization = MessagePack.pack data
      sha1 = Digest::SHA1.hexdigest serialization

      write_redis type, sha1, serialization
      Thread.new { write_file type, sha1, serialization }

      sha1
    end

    def self.read(type, sha1)
      serialization = read_redis(type, sha1) || read_file(type, sha1)
      MessagePack.unpack serialization
    end

    private

    def self.write_redis(type, sha1, serialization)
      Eternity.redis.call 'SET', Eternity.namespace[:blob][type][sha1], serialization, 
                          'EX', Eternity.blob_cache_expiration
    end

    def self.read_redis(type, sha1)
      Eternity.redis.call 'GET', Eternity.namespace[:blob][type][sha1]
    end

    def self.write_file(type, sha1, serialization)
      path = File.join Eternity.data_path, 'blob', type.to_s
      FileUtils.mkpath path unless Dir.exists? path
      File.write File.join(path, sha1), serialization
    end

    def self.read_file(type, sha1)
      serialization = IO.read(File.join(Eternity.data_path, 'blob', type.to_s, sha1))
      Thread.new { write_redis type, sha1, serialization }
      serialization

    rescue Errno::ENOENT
      raise "Blob not found. #{type.capitalize}: #{sha1}"
    end
  
  end
end